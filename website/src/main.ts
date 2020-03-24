import app from "apprun";
import {Auth, Paintings} from "./api";

app.on("#", (route, ...p) => {
    app.run(`#/${route || ""}`, ...p);
});

Auth.login({name: "bob", password: "zilla"});
Auth.refresh();

Paintings.list().then(console.log);

//app.run("/get-user");
