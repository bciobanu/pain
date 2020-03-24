import app from "apprun";

import "./components/header";
import "./components/home";
import "./components/upload-painting";
import "./components/login";
import "./components/register";

app.on("#", (route, ...p) => {
    app.run(`#/${route || ""}`, ...p);
});

app.run("/refresh");

const dataPolling = () => {
    setTimeout(() => app.run("/refresh"));
};

// poor man's websockets
setInterval(dataPolling, 10000); // every 10 seconds
