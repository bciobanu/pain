import app from "apprun";

import './components/home';

app.on("#", (route, ...p) => {
    app.run(`#/${route || ""}`, ...p);
});

app.run("/refresh");
