# API Mock Server

Servidor API mock para la aplicación To-Do List.

## Instalación

```bash
cd api
npm install
```

## Ejecución

```bash
# Modo desarrollo (con auto-reload)
npm run dev

# Modo producción
npm start
```

El servidor estará disponible en `http://localhost:3000`

## Endpoints

- `GET /tasks` - Obtener todas las tareas
- `GET /tasks/:id` - Obtener una tarea por ID
- `POST /tasks` - Crear una nueva tarea
- `PUT /tasks/:id` - Actualizar una tarea
- `DELETE /tasks/:id` - Eliminar una tarea

## Notas

- Los datos se almacenan en memoria (se pierden al reiniciar el servidor)
- Soporta Idempotency-Key header para evitar duplicaciones en reintentos
- El servidor acepta CORS desde cualquier origen

