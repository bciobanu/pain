import {app, Component, on} from "apprun";

class LoginComponent extends Component {
    state = {}

    view = state => {
        return (
            <div>
                <p>PLM</p>
            </div>
        );
    }

    @on("#/login") login = (state) => state;
};

export default new LoginComponent().start("pain-app");
