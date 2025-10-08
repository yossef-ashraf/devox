const express = require('express');
const mysql = require('mysql');

const app = express();
app.use(express.json());

// تكوين اتصال قاعدة البيانات
const connection = mysql.createConnection({
  host: 'mysql',
  user: 'root',
  password: 'secret',
  database: 'mydb'
});

// إنشاء جدول الموظفين
connection.query(`
  CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
  )
`);

// إنشاء موظف جديد
app.post('/employees', (req, res) => {
  const { name, email } = req.body;
  connection.query(
    'INSERT INTO employees (name, email) VALUES (?, ?)',
    [name, email],
    (err, result) => {
      if (err) throw err;
      res.status(201).json({ id: result.insertId, name, email });
    }
  );
});

// الحصول على قائمة الموظفين
app.get('/employees', (req, res) => {
  connection.query('SELECT * FROM employees', (err, rows) => {
    if (err) throw err;
    res.json(rows);
  });
});

// تحديث معلومات موظف
app.put('/employees/:id', (req, res) => {
  const { id } = req.params;
  const { name, email } = req.body;
  connection.query(
    'UPDATE employees SET name = ?, email = ? WHERE id = ?',
    [name, email, id],
    (err, result) => {
      if (err) throw err;
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Employee not found' });
      }
      res.json({ id, name, email });
    }
  );
});

// حذف موظف
app.delete('/employees/:id', (req, res) => {
  const { id } = req.params;
  connection.query(
    'DELETE FROM employees WHERE id = ?',
    [id],
    (err, result) => {
      if (err) throw err;
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Employee not found' });
      }
      res.sendStatus(204);
    }
  );
});

app.listen(3000, () => {
  console.log('Server listening on port 3000');
});