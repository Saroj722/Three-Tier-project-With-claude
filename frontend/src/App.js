import React, { useEffect, useState } from 'react';
import './App.css';

// Relative path on purpose: in AWS, the ALB routes requests starting with
// /api/* to the backend ECS target group, and everything else to the
// frontend target group. Locally, nginx.conf does the same proxying.
// This means the exact same build artifact works in both places with
// zero rebuilds or env-specific config.
const API_BASE = '/api/tasks';

const STATUS_LABELS = {
  todo: 'To Do',
  in_progress: 'In Progress',
  done: 'Done',
};

function App() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  const fetchTasks = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(API_BASE);
      if (!res.ok) throw new Error(`Server responded ${res.status}`);
      const data = await res.json();
      setTasks(data);
    } catch (err) {
      setError('Could not reach the API. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const addTask = async (e) => {
    e.preventDefault();
    if (!title.trim()) return;
    try {
      const res = await fetch(API_BASE, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description }),
      });
      if (!res.ok) throw new Error('Failed to create task');
      setTitle('');
      setDescription('');
      fetchTasks();
    } catch (err) {
      setError('Could not create the task.');
    }
  };

  const cycleStatus = async (task) => {
    const order = ['todo', 'in_progress', 'done'];
    const next = order[(order.indexOf(task.status) + 1) % order.length];
    try {
      await fetch(`${API_BASE}/${task.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...task, status: next }),
      });
      fetchTasks();
    } catch (err) {
      setError('Could not update the task.');
    }
  };

  const deleteTask = async (id) => {
    try {
      await fetch(`${API_BASE}/${id}`, { method: 'DELETE' });
      fetchTasks();
    } catch (err) {
      setError('Could not delete the task.');
    }
  };

  return (
    <div className="app">
      <header className="header">
        <h1>Task Manager</h1>
        <p className="subtitle">React &middot; Node/Express &middot; MySQL &middot; running on AWS ECS Fargate</p>
      </header>

      <form className="add-form" onSubmit={addTask}>
        <input
          type="text"
          placeholder="Task title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <input
          type="text"
          placeholder="Description (optional)"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
        <button type="submit">Add Task</button>
      </form>

      {error && <div className="error-banner">{error}</div>}

      {loading ? (
        <p className="empty-state">Loading tasks…</p>
      ) : tasks.length === 0 ? (
        <p className="empty-state">No tasks yet. Add one above.</p>
      ) : (
        <ul className="task-list">
          {tasks.map((task) => (
            <li key={task.id} className={`task-item status-${task.status}`}>
              <div className="task-info">
                <span className="task-title">{task.title}</span>
                {task.description && <span className="task-desc">{task.description}</span>}
              </div>
              <div className="task-actions">
                <button className="status-btn" onClick={() => cycleStatus(task)}>
                  {STATUS_LABELS[task.status]}
                </button>
                <button className="delete-btn" onClick={() => deleteTask(task.id)}>
                  Delete
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default App;
