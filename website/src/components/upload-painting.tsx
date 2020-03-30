import {app, on, Component} from "apprun";
import {API_URL} from "../fetch";

class UploadPaintingComponent extends Component {
    state = {};

    view = state => {
        return (
            <div class="uk-flex uk-flex-center">
                <form action={API_URL + "upload-painting"} method="post" enctype="multipart/form-data">
                    <legend class="uk-legend">Upload a new painting</legend>

                    <div class="uk-margin">
                        <input class="uk-input" name="Name" type="text" placeholder="Name" />
                    </div>
                    <div class="uk-margin">
                        <input class="uk-input" name="Artist" type="text" placeholder="Artist" />
                    </div>

                    <div class="uk-margin">
                        <input class="uk-input" name="Year" type="text" placeholder="Year" />
                    </div>

                    <div class="uk-margin">
                        <input class="uk-input" name="Medium" type="text" placeholder="Medium" />
                    </div>

                    <div class="uk-margin">
                        <textarea
                            class="uk-textarea"
                            name="Description"
                            rows="5"
                            cols="80"
                            placeholder="Description"></textarea>
                    </div>

                    <div class="uk-margin">
                        <div uk-form-custom class="uk-width-expand">
                            <input name="image" type="file" />
                            <button class="uk-button uk-button-default uk-width-expand" type="button" tabindex="-1">
                                Choose your best image
                            </button>
                        </div>
                    </div>

                    <div class="uk-margin">
                        <button class="uk-button uk-button-primary uk-width-expand">Submit</button>
                    </div>
                </form>
            </div>
        );
    };

    @on("#/upload-painting") uploadPainting = state => state;
}

export default new UploadPaintingComponent().mount("pain-app");
