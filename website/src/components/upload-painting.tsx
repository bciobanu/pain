import {app, on, Component} from "apprun";

class UploadPaintingComponent extends Component {
    state = {}

    view = state => {
        return (
            <div class="uk-flex uk-flex-center">
                <form>
                    <legend class="uk-legend">Upload a new painting</legend>

                    <div class="uk-margin">
                        <input class="uk-input" type="text" placeholder="Name"/>
                    </div>
                    <div class="uk-margin">
                        <input class="uk-input" type="text" placeholder="Artist"/>
                    </div>

                    <div class="uk-margin">
                        <input class="uk-input" type="text" placeholder="Year"/>
                    </div>

                    <div class="uk-margin">
                        <input class="uk-input" type="text" placeholder="Medium"/>
                    </div>

                    <div class="uk-margin">
                        <textarea class="uk-textarea" rows="5" cols="80" placeholder="Description"></textarea>
                    </div>

                    <div class="uk-margin">
                        <div uk-form-custom class="uk-width-expand">
                            <input type="file" />
                            <button class="uk-button uk-button-default uk-width-expand" type="button" tabindex="-1">Choose your best image</button>
                        </div>
                    </div>
                </form>
            </div>
        )
    }

    @on("#/upload-painting") uploadPainting = state => state;
};

export default new UploadPaintingComponent().mount("pain-app");
