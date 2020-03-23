import {app, Component} from "apprun";

class App extends Component {
    view = () => <div>Test</div>;
}

app.render(document.body, <App />);
