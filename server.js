const express = require("express");
const path = require("path");
const convert = require("convert-units");

const app = express();
const PORT = 3000;

// Set up EJS and public folder
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "public")));

// GET: Homepage
app.get("/", (req, res) => {
  const measures = convert().measures(); // ['length', 'mass', 'speed', etc.]
  const units = [];
  const result = null;

  // Render index first, then wrap inside layout
  res.render("index", { measures, units, result }, (err, html) => {
    if (err) throw err;
    res.render("layout", { body: html });
  });
});

// POST: Perform conversion
app.post("/convert", (req, res) => {
  const { measure, from, to, value } = req.body;
  const measures = convert().measures();
  const units = convert().possibilities(measure);
  let result = null;

  try {
    result = convert(parseFloat(value)).from(from).to(to);
  } catch (err) {
    result = "Invalid conversion";
  }

  // Render index then inject into layout
  res.render("index", { measures, units, result }, (err, html) => {
    if (err) throw err;
    res.render("layout", { body: html });
  });
});

// POST: Return available units for selected category (AJAX)
app.post("/units", (req, res) => {
  const { measure } = req.body;
  const units = convert().possibilities(measure);
  res.json(units);
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Konvert running at http://localhost:${PORT}`);
});

