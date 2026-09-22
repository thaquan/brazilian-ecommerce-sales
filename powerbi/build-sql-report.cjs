// Reuse the approved native report layout against the local SQL Import model.
const fs=require('fs'),path=require('path');
const src=path.join(__dirname,'RPT_Olist_Analytics.Report');
const dst=path.join(__dirname,'Olist_SQLServer.Report');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));
const write=(p,v)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,JSON.stringify(v,null,2)+'\n');};
const srcDef=path.join(src,'definition'),dstDef=path.join(dst,'definition');
const meta=read(path.join(srcDef,'pages','pages.json'));
const pageIds=meta.pageOrder.filter(id=>read(path.join(srcDef,'pages',id,'page.json')).displayName!=='Data Health');
// Existing target was backed up before first run. Delete only its page tree.
const targetPages=path.resolve(dstDef,'pages');
if(!targetPages.startsWith(path.resolve(dst)+path.sep))throw Error('Unsafe page path');
if(fs.existsSync(targetPages))fs.rmSync(targetPages,{recursive:true});
for(const id of pageIds)fs.cpSync(path.join(srcDef,'pages',id),path.join(targetPages,id),{recursive:true});
fs.cpSync(path.join(src,'StaticResources'),path.join(dst,'StaticResources'),{recursive:true});
for(const file of ['report.json','version.json'])fs.copyFileSync(path.join(srcDef,file),path.join(dstDef,file));
write(path.join(targetPages,'pages.json'),{...meta,pageOrder:pageIds,activePageName:pageIds[0]});
function adapt(v){
 if(Array.isArray(v))return v.map(adapt);
 if(v&&typeof v==='object'){
  const out={};for(const [k,x]of Object.entries(v)){
   if(k==='Schema'&&x==='extension')continue;
   out[k]=adapt(x);
  }
  if(out.visualType==='pageNavigator')for(const layout of out.objects.layout)layout.properties.rowCount={expr:{Literal:{Value:'5L'}}};
  return out;
 }
 if(typeof v==='string'&&v.startsWith('extension.'))return v.slice(10);
 return v;
}
function walk(dir){for(const d of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,d.name);if(d.isDirectory())walk(p);else if(d.name.endsWith('.json'))write(p,adapt(read(p)));}}
walk(targetPages);
// Report metrics now reside in the Import semantic model, not report extensions.
const ext=path.join(dstDef,'reportExtensions.json');if(fs.existsSync(ext))fs.unlinkSync(ext);
console.log('Copied five business pages; preserved SQL model byPath binding.');
