# tfg

## Manual básico para trabajar con ramas en GitHub

Este proyecto utiliza **ramas (branches)** para que varias personas puedan trabajar en paralelo sin sobrescribir el trabajo de otros. A continuación se explica el flujo de trabajo recomendado.

---

### 1. Actualizar el repositorio antes de empezar

Antes de comenzar a trabajar es importante descargar los últimos cambios del repositorio.

```bash
git pull
```

Esto asegura que estás trabajando con la versión más reciente del proyecto.

---

### 2. Crear una nueva rama

Cada nueva funcionalidad o cambio debe hacerse en una rama propia.

```bash
git checkout -b nombre-de-la-rama
```

Ejemplo:

```bash
git checkout -b feature-login
```

Esto crea una nueva rama y cambia automáticamente a ella.

---

### 3. Realizar cambios en el proyecto

Una vez en la rama puedes modificar archivos, añadir funcionalidades o corregir errores.

---

### 4. Guardar los cambios (commit)

Después de hacer cambios se deben guardar en el repositorio local.

```bash
git add .
git commit -m "Descripción breve de los cambios realizados"
```

---

### 5. Subir la rama al repositorio remoto

Para subir los cambios a GitHub se utiliza:

```bash
git push origin nombre-de-la-rama
```

Ejemplo:

```bash
git push origin feature-login
```

---

### 6. Crear un Pull Request

Una vez subida la rama:

1. Ir al repositorio en GitHub.
2. Seleccionar **Compare & Pull Request**.
3. Revisar los cambios realizados.
4. Crear el **Pull Request** hacia la rama `main`.

Esto permite revisar los cambios antes de integrarlos en el proyecto principal.

---

### 7. Unir los cambios a la rama principal

Después de revisar los cambios, el Pull Request se puede integrar (merge) en la rama `main`.

---

### 8. Actualizar el proyecto después del merge

Una vez que los cambios se han unido a `main`, todos los miembros del equipo deben actualizar su repositorio:

```bash
git pull
```

---

## Flujo de trabajo resumido

```
git pull
git checkout -b nombre-rama
(hacer cambios)
git add .
git commit -m "mensaje"
git push origin nombre-rama
```

Después se crea un **Pull Request** en GitHub para integrar los cambios en `main`.

---

## Recomendaciones

* Crear una rama para cada nueva funcionalidad o corrección.
* Usar nombres claros para las ramas (`feature-login`, `fix-bug-menu`, etc.).
* Actualizar el repositorio frecuentemente con `git pull`.
* Revisar los cambios antes de hacer merge a `main`.

Este flujo de trabajo permite que varias personas colaboren en el proyecto de forma organizada y segura.
