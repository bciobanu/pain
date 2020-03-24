import app from "apprun";

const API_URL = "http://localhost:8080/";
const TOKEN_KEY = "jwt";

export function getToken() {
    return window?.localStorage.getItem(TOKEN_KEY) || "";
}

export function setToken(token: string) {
    app["token"] = token;
    app.run("/token-changed", token);

    if (!window.localStorage) {
        return;
    }
    if (token) {
        window.localStorage.setItem(TOKEN_KEY, token);
    } else {
        window.localStorage.removeItem(TOKEN_KEY);
    }
}

export async function fetchAsync(method: "GET" | "POST" | "DELETE" | "PUT", url: string, body?: any) {
    const headers = {
        "Content-Type": "application/json; charset=utf-8",
    };
    const token = getToken();
    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await window["fetch"](`${API_URL}${url}`, {
        method,
        headers,
        credentials: "include",
        body: body && JSON.stringify(body),
    });
    if (response.status === 401) {
        setToken(null);
        throw new Error("401");
    }

    const result = await response.text().then(text => (text ? JSON.parse(text) : {}));
    if (!response.ok) {
        throw result;
    } else if (result.hasOwnProperty("error")) {
        throw new Error(result["error"]);
    }
    return result;
}

export function serializeObject<T>(form) {
    let obj = {};
    if (typeof form == "object" && form.nodeName == "FORM") {
        for (let i = 0; i < form.elements.length; i++) {
            const field = form.elements[i];
            if (
                field.name &&
                field.type != "file" &&
                field.type != "reset" &&
                field.type != "submit" &&
                field.type != "button"
            ) {
                if (field.type == "select-multiple") {
                    obj[field.name] = "";
                    let tempvalue = "";
                    for (let j = 0; j < form.elements[i].options.length; j++) {
                        if (field.options[j].selected) tempvalue += field.options[j].value + ";";
                    }
                    if (tempvalue.charAt(tempvalue.length - 1) === ";")
                        obj[field.name] = tempvalue.substring(0, tempvalue.length - 1);
                } else if ((field.type != "checkbox" && field.type != "radio") || field.checked) {
                    obj[field.name] = field.value;
                }
            }
        }
    }
    return obj as T;
}
