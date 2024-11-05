window.addEventListener("load", async ()=>{
    webkit.messageHandlers.backgroundListener.postMessage(document.body.innerHTML);
});

function handleMessage(data) {
    webkit.messageHandlers.backgroundListener.postMessage("Reply from background script : " + data);

    try {
        let json = JSON.parse(data);
        
        if ( json.type !== undefined ) {
     //       webkit.messageHandlers.backgroundListener.postMessage("found a barcode type");
     //       webkit.messageHandlers.backgroundListener.postMessage(json.type);
            
            JsBarcode('#barcode', json.data, {format: json.type,displayValue: true,height:100})
      //      webkit.messageHandlers.backgroundListener.postMessage("executed JsBarcode");
            webkit.messageHandlers.backgroundListener.postMessage(document.body.innerHTML);
        }
    } catch(error) {
        webkit.messageHandlers.backgroundListener.postMessage("error raised");
    }
    //webkit.messageHandlers.backgroundListener.postMessage("finished execution of handleMessage");
}
