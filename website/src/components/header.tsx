import {app, Component, on} from "apprun";

class HeaderComponent extends Component {
    state = {};

    view = state => {
        return (
            <nav class="uk-navbar-container uk-margin" uk-navbar>
                <div class="uk-navbar-left">
                    <a class="uk-navbar-item uk-logo" href="#">
                        Pain
                    </a>
                </div>
                <div class="uk-navbar-right">
                    <div class="uk-navbar-item">
                        <a href="#/login">Login</a>
                    </div>
                </div>
            </nav>
        );
    };
}

export default new HeaderComponent().start("header");
