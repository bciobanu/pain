const API_URL = "http://localhost:8080/";
const TOKEN_KEY = "jwt";

export function getToken() {
    return window?.localStorage.getItem(TOKEN_KEY) || "";
}

export function setToken(token: string) {
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
        body: body && JSON.stringify(body),
    });
    if (response.status === 401) {
        setToken(null);
        throw new Error("401");
    }

    const result = await response.text().then(text => (text ? JSON.parse(text) : {}));
    if (!response.ok) {
        throw result;
    }
    return result;
}
