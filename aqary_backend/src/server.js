const app = require("./app");

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`AQARY backend listening on port ${PORT} (${process.env.NODE_ENV || "development"})`);
});
