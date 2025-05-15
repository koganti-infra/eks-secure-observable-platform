const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Hello from Service A");
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Service A listening on port ${port}`);
});