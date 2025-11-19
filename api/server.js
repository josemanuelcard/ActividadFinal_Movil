const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Almacenamiento en memoria (en producción usar una base de datos)
let tasks = [];
let processedIdempotencyKeys = new Set();

// Helper para generar IDs únicos
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Helper para validar tarea
function validateTask(task) {
  if (!task.title || typeof task.title !== 'string' || task.title.trim() === '') {
    return { valid: false, error: 'El título es requerido' };
  }
  if (task.completed !== undefined && typeof task.completed !== 'boolean') {
    return { valid: false, error: 'completed debe ser un booleano' };
  }
  return { valid: true };
}

// GET /tasks - Obtener todas las tareas
app.get('/tasks', (req, res) => {
  try {
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener las tareas' });
  }
});

// GET /tasks/:id - Obtener una tarea por ID
app.get('/tasks/:id', (req, res) => {
  try {
    const task = tasks.find(t => t.id === req.params.id);
    if (!task) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }
    res.status(200).json(task);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener la tarea' });
  }
});

// POST /tasks - Crear una nueva tarea
app.post('/tasks', (req, res) => {
  try {
    const idempotencyKey = req.headers['idempotency-key'];
    
    // Verificar idempotencia
    if (idempotencyKey && processedIdempotencyKeys.has(idempotencyKey)) {
      // Retornar la tarea existente si ya fue procesada
      const existingTask = tasks.find(t => t.idempotencyKey === idempotencyKey);
      if (existingTask) {
        return res.status(200).json(existingTask);
      }
    }

    const taskData = req.body;
    const validation = validateTask(taskData);
    
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    const now = new Date().toISOString();
    const task = {
      id: taskData.id || generateId(),
      title: taskData.title.trim(),
      completed: taskData.completed || false,
      updatedAt: taskData.updatedAt || now,
    };

    if (idempotencyKey) {
      task.idempotencyKey = idempotencyKey;
      processedIdempotencyKeys.add(idempotencyKey);
    }

    tasks.push(task);
    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ error: 'Error al crear la tarea' });
  }
});

// PUT /tasks/:id - Actualizar una tarea
app.put('/tasks/:id', (req, res) => {
  try {
    const idempotencyKey = req.headers['idempotency-key'];
    
    // Verificar idempotencia
    if (idempotencyKey && processedIdempotencyKeys.has(idempotencyKey)) {
      const existingTask = tasks.find(t => t.id === req.params.id);
      if (existingTask) {
        return res.status(200).json(existingTask);
      }
    }

    const taskIndex = tasks.findIndex(t => t.id === req.params.id);
    if (taskIndex === -1) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    const taskData = req.body;
    const validation = validateTask(taskData);
    
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    const now = new Date().toISOString();
    const updatedTask = {
      ...tasks[taskIndex],
      title: taskData.title.trim(),
      completed: taskData.completed !== undefined ? taskData.completed : tasks[taskIndex].completed,
      updatedAt: taskData.updatedAt || now,
    };

    if (idempotencyKey) {
      updatedTask.idempotencyKey = idempotencyKey;
      processedIdempotencyKeys.add(idempotencyKey);
    }

    tasks[taskIndex] = updatedTask;
    res.status(200).json(updatedTask);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar la tarea' });
  }
});

// DELETE /tasks/:id - Eliminar una tarea
app.delete('/tasks/:id', (req, res) => {
  try {
    const idempotencyKey = req.headers['idempotency-key'];
    
    // Verificar idempotencia
    if (idempotencyKey && processedIdempotencyKeys.has(idempotencyKey)) {
      // Si ya fue procesada, retornar éxito
      return res.status(204).send();
    }

    const taskIndex = tasks.findIndex(t => t.id === req.params.id);
    if (taskIndex === -1) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    tasks.splice(taskIndex, 1);
    
    if (idempotencyKey) {
      processedIdempotencyKeys.add(idempotencyKey);
    }

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar la tarea' });
  }
});

// Endpoint para limpiar datos (útil para testing)
app.post('/tasks/clear', (req, res) => {
  tasks = [];
  processedIdempotencyKeys.clear();
  res.status(200).json({ message: 'Datos limpiados' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor API mock corriendo en http://localhost:${PORT}`);
  console.log(`📝 Endpoints disponibles:`);
  console.log(`   GET    /tasks`);
  console.log(`   GET    /tasks/:id`);
  console.log(`   POST   /tasks`);
  console.log(`   PUT    /tasks/:id`);
  console.log(`   DELETE /tasks/:id`);
});

