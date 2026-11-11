const L=h=>{const c=h.match(/\w\w/g).map(x=>parseInt(x,16)/255).map(v=>v<=.03928?v/12.92:((v+.055)/1.055)**2.4);return .2126*c[0]+.7152*c[1]+.0722*c[2]};
const r=(a,b)=>{const[x,y]=[L(a),L(b)].sort((p,q)=>q-p);return ((x+.05)/(y+.05)).toFixed(2)};
const pairs=process.argv.slice(2);for(let i=0;i<pairs.length;i+=2)console.log(pairs[i],pairs[i+1],r(pairs[i].slice(1),pairs[i+1].slice(1)));
