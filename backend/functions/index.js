const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

// Inicialización de Firebase Admin para acceso a Firestore
admin.initializeApp();
const db = admin.firestore();

const app = express();

// Configuración de Express
app.use(cors({ origin: true }));
app.use(express.json());

// --- ENDPOINTS ---

// Test de salud de la API
app.get("/hello", (req, res) => {
  res.status(200).send("¡La API de TaGo está viva y funcionando!");
});

// MARCADORES (TaGos)
app.get("/marcadores", async (req, res) => {
  try {
    const snapshot = await db.collection("marcadores").get();
    const marcadores = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(marcadores);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/marcadores", async (req, res) => {
  try {
    const data = req.body;
    const id = data.id;
    await db.collection("marcadores").doc(id).set(data);
    res.status(201).json({ message: "Marcador guardado" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// USUARIOS
app.get("/usuarios", async (req, res) => {
  try {
    const snapshot = await db.collection("usuarios").get();
    const usuarios = snapshot.docs.map(doc => ({ uid: doc.id, ...doc.data() }));
    res.status(200).json(usuarios);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get("/usuarios/:uid", async (req, res) => {
  try {
    const doc = await db.collection("usuarios").doc(req.params.uid).get();
    if (!doc.exists) return res.status(404).send("Usuario no encontrado");
    res.status(200).json(doc.data());
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/usuarios", async (req, res) => {
  try {
    const { uid, ...data } = req.body;
    await db.collection("usuarios").doc(uid).set(data, { merge: true });
    res.status(200).json({ message: "Perfil actualizado" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ESCANEOS (Colección personal de TaGos descubiertos)

// Obtener todos los IDs de TaGos escaneados por un usuario
app.get("/usuarios/:uid/escaneos", async (req, res) => {
  try {
    const snapshot = await db.collection("usuarios").doc(req.params.uid).collection("escaneos").get();
    const escaneos = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(escaneos);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Verificar escaneo individual
app.get("/usuarios/:uid/escaneos/:tagoId", async (req, res) => {
  try {
    const doc = await db.collection("usuarios").doc(req.params.uid).collection("escaneos").doc(req.params.tagoId).get();
    if (doc.exists) {
      res.status(200).json({ escaneado: true });
    } else {
      res.status(404).json({ escaneado: false });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Registrar un nuevo descubrimiento
app.post("/usuarios/:uid/escaneos/:tagoId", async (req, res) => {
  try {
    const { uid, tagoId } = req.params;
    await db.collection("usuarios").doc(uid).collection("escaneos").doc(tagoId).set({
      fechaEscaneo: new Date().toISOString()
    });
    res.status(201).json({ message: "TaGo registrado en el libro" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

exports.api = onRequest(app);
