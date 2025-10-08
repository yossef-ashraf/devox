const express = require('express');
const mongoose = require('mongoose');

const app = express();
app.use(express.json());

// اتصال بقاعدة بيانات MongoDB
mongoose.connect('mongodb://mongo:27017/myapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// تعريف نموذج الموظف
const Employee = mongoose.model('Employee', {
  name: String,
  email: String
});

// إنشاء موظف جديد
app.post('/employees', async (req, res) => {
  const { name, email } = req.body;
  const employee = new Employee({ name, email });
  await employee.save();
  res.status(201).json(employee);
});

// الحصول على قائمة الموظفين
app.get('/employees', async (req, res) => {
  const employees = await Employee.find({});
  res.json(employees);
});

// تحديث معلومات موظف
app.put('/employees/:id', async (req, res) => {
  const { id } = req.params;
  const { name, email } = req.body;
  const employee = await Employee.findByIdAndUpdate(
    id,
    { name, email },
    { new: true }
  );
  if (!employee) {
    return res.status(404).json({ error: 'Employee not found' });
  }
  res.json(employee);
});

// حذف موظف
app.delete('/employees/:id', async (req, res) => {
  const { id } = req.params;
  const employee = await Employee.findByIdAndDelete(id);
  if (!employee) {
    return res.status(404).json({ error: 'Employee not found' });
  }
  res.sendStatus(204);
});

app.listen(3000, () => {
  console.log('Server listening on port 3000');
});