## Use your own reddit API credentials in Apollo


### Creating an API credential:

sign out of all accounts in Apollo before installing

1. Sign into your reddit account (on desktop) and go here: https://reddit.com/prefs/apps
2. Click the `are you a developer? create an app...` button
3. Fill in the fields
	* name: Use whatever
	* Choose `Installed App`
	* description: bs
	* about url: bs
	* redirect uri: `apollo://reddit-oauth`
4. `create app`

5. After creating the app you'll get a client identifier; it'll be a bunch of random characters.

6. Enter it in the Client ID in the settings and tap "Set RedditClientID".

7. It currently works without Imgur settings.


Added ability to upload and delete images to Imgur
(Multiple images not supported)

Repo: https://cydia.ichitaso.com
