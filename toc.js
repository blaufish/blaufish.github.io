let txt = ""
for (const a of document.querySelectorAll('h2, h3')) {
 if (a.className == 'footer-heading') continue
 if (a.tagName == "H2") {
   txt = txt + "* "
 }
 else if (a.tagName == "H3") {
   txt = txt + "  * "
 }
 txt = txt + "[" + a.innerText + "](#" + a.id + ")\n"
}
console.log(txt)
