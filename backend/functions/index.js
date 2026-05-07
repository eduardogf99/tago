const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

admin.initializeApp();
const db = admin.firestore();
const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

// --- ENDPOINTS ---

// Registro de escaneo: Aseguramos que se guarde el campo tagoId para poder buscarlo después
app.post("/usuarios/:uid/escaneos/:tagoId", async (req, res) => {
  try {
    const { uid, tagoId } = req.params;
    const batch = db.batch();
    const userRef = db.collection("usuarios").doc(uid);
    const escaneoRef = userRef.collection("escaneos").doc(tagoId);

    // Aseguramos que tagoId esté dentro del documento para que collectionGroup lo encuentre
    batch.set(escaneoRef, {
      tagoId: tagoId,
      fechaEscaneo: new Date().toISOString()
    }, { merge: true });

    batch.set(userRef, {
      totalEscaneos: admin.firestore.FieldValue.increment(1)
    }, { merge: true });

    await batch.commit();
    res.status(201).json({ message: "Registrado con éxito" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Borrado masivo y decremento de contadores (Versión Robusta)
app.delete("/marcadores/:tagoId", async (req, res) => {
  try {
    const tagoId = req.params.tagoId.trim();
    console.log(`>>> PETICIÓN DE BORRADO MASIVO: ${tagoId}`);

    // A. BUSCAR EN TODOS LOS USUARIOS (Hacer esto primero y siempre)
    // Requiere índice de grupo de colecciones para 'escaneos' con campo 'tagoId'
    const snapshot = await db.collectionGroup("escaneos")
      .where("tagoId", "==", tagoId)
      .get();

    console.log(`>>> Usuarios detectados para limpieza: ${snapshot.size}`);

    if (!snapshot.empty) {
      let batch = db.batch();
      let count = 0;

      for (const doc of snapshot.docs) {
        const userRef = doc.ref.parent.parent; // Llegamos al doc del usuario

        batch.delete(doc.ref); // Borrar el escaneo
        batch.set(userRef, {
          totalEscaneos: admin.firestore.FieldValue.increment(-1)
        }, { merge: true });

        count++;
        if (count >= 200) { // 200 documentos * 2 ops = 400 ops (límite 500)
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }

    // B. Borrar el marcador global y rastro del creador
    const marcadorDoc = await db.collection("marcadores").doc(tagoId).get();
    const finalBatch = db.batch();

    // Si existe el marcador, identificamos al creador para borrar su rastro
    if (marcadorDoc.exists) {
      const creadorId = marcadorDoc.data().creadorId;
      if (creadorId) {
        finalBatch.delete(db.collection("usuarios").doc(creadorId).collection("creados").doc(tagoId));
      }
      finalBatch.delete(db.collection("marcadores").doc(tagoId));
    }

    await finalBatch.commit();
    console.log(`>>> BORRADO COMPLETADO PARA ${tagoId}`);

    res.status(200).json({
      message: "Limpieza completada",
      usuariosAfectados: snapshot.size
    });

  } catch (error) {
    console.error("!!! ERROR EN EL PROCESO DE BORRADO:", error);
    res.status(500).json({ error: error.message });
  }
});

exports.api = onRequest(app);
