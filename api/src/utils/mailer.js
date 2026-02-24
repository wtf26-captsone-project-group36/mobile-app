const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

async function sendOTPEmail(toEmail, otp) {
  await transporter.sendMail({
    from: `"HerVest" <${process.env.GMAIL_USER}>`,
    to: toEmail,
    subject: 'Your HerVest verification code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;">
        <h2>Verify your account</h2>
        <p>Enter this code to complete your signup:</p>
        <h1 style="letter-spacing: 10px; font-size: 48px; color: #0f766e;">${otp}</h1>
        <p>This code expires in 10 minutes. Do not share it with anyone.</p>
      </div>
    `
  });
}

async function sendPasswordResetEmail(toEmail, otp) {
  await transporter.sendMail({
    from: `"HerVest" <${process.env.GMAIL_USER}>`,
    to: toEmail,
    subject: 'Your HerVest password reset code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;">
        <h2>Reset your password</h2>
        <p>Enter this code to reset your password:</p>
        <h1 style="letter-spacing: 10px; font-size: 48px; color: #0f766e;">${otp}</h1>
        <p>This code expires in 10 minutes. Do not share it with anyone.</p>
      </div>
    `
  });
}

module.exports = { sendOTPEmail, sendPasswordResetEmail };
