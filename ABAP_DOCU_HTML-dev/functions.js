function resolvePath(linked_file) {
  try {
    if (!linked_file) return linked_file;
    var lower = linked_file.toLowerCase();
    if (lower.indexOf("abap") === 0) {
      return "docs/core/" + linked_file;
    } else if (lower.indexOf("aben") === 0) {
      return "docs/advanced/" + linked_file;
    } else if (lower.indexOf("dynp") === 0) {
      return "docs/ui/" + linked_file;
    }
    return linked_file;
  } catch (e) { return linked_file; }
}

function call_link(linked_file)
{
   var resolved = resolvePath(linked_file);
   if(parent.frames.length>0){
     parent.window.frames["basefrm"].window.location = resolved;
     parent.window.frames["treeframe"].window.location = "abap_docu_tree.htm?file=" + linked_file;}
   else {
     window.location = resolved;}
}
function call_search(linked_file)
{
   var textinput = window.query.value;
   while (textinput.indexOf("&")>-1){    textinput = textinput.replace("&","%26") }
   while (textinput.indexOf("+")>-1){    textinput = textinput.replace("+","%2B") }
   while (textinput.indexOf("=")>-1){    textinput = textinput.replace("=","%3D") }
   while (textinput.indexOf("?")>-1){    textinput = textinput.replace("?","%3F") }
   while (textinput.indexOf(" ")>-1){    textinput = textinput.replace(" ","%20") }
   while (textinput.indexOf('"')>-1){    textinput = textinput.replace('"',"%22") }
   while (textinput.indexOf("<")>-1){    textinput = textinput.replace("<","%3C") }
   while (textinput.indexOf(">")>-1){    textinput = textinput.replace(">","%3E") }
   if ( textinput.search( "\"" ) != -1 )
      { textinput = "\""; }
   linked_file = linked_file + "?query=" + textinput;
   if(parent.frames.length>0){
     parent.window.frames["basefrm"].window.location = linked_file;
     parent.window.frames["treeframe"].window.location = "abap_docu_tree.htm?file=" + linked_file;}
   else {
     window.location = linked_file;}
}
function getInput()
{
  var textinput = window.query.value;
  if ( event.keyCode == 13 ){
   call_search("search.htm"); }
}

// Rewrite image/icon paths to centralized assets/images
function patchAssetsPaths() {
  try {
    // Rewrite <img src> that are plain file names (no slash) to assets/images
    var imgs = document.getElementsByTagName('img');
    for (var i = 0; i < imgs.length; i++) {
      var el = imgs[i];
      var srcAttr = el.getAttribute('src');
      if (!srcAttr) continue;
      // filename only, common image extensions
      if (/^[^\/]+\.(gif|jpg|jpeg|png|ico)$/i.test(srcAttr)) {
        el.setAttribute('src', 'assets/images/' + srcAttr);
      }
    }
    // Rewrite <link rel=icon/shortcut icon>
    var links = document.getElementsByTagName('link');
    for (var j = 0; j < links.length; j++) {
      var lk = links[j];
      var rel = (lk.getAttribute('rel') || '').toLowerCase();
      var href = lk.getAttribute('href');
      if ((rel.indexOf('icon') !== -1) && href && /^[^\/]+\.(ico|png|gif)$/i.test(href)) {
        lk.setAttribute('href', 'assets/images/' + href);
      }
    }
  } catch(e) { /* ignore */ }
}

if (typeof window !== 'undefined') {
  if (document && document.addEventListener) {
    document.addEventListener('DOMContentLoaded', patchAssetsPaths);
  }
}
