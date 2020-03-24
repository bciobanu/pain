import {app, Component, on} from "apprun";

class HeaderComponent extends Component {
    state = {};

    view = state => {
        const {token} = state;
        return (
            <nav class="uk-navbar-container uk-margin" uk-navbar>
                <div class="uk-navbar-left">
                    <a class="uk-navbar-item uk-logo" href="#">
                        Pain
                    </a>
                </div>
                {!token &&
                    <div class="uk-navbar-right">
                        <div class="uk-navbar-item">
                            <a href="#/login">Login</a>
                        </div>
                    </div>
                }
            </nav>
        );
    };

    @on("/token-changed") tokenChanged = (state, token) => {
        return {token: token};
    };
}

export default new HeaderComponent().start("header");
