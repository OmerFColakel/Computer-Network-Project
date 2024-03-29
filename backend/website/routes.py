import os
import uuid

from flask import request, Blueprint, jsonify, make_response, session, send_file
import bcrypt

from website import db
from website.models import User

main = Blueprint('main', __name__)

root_directory = os.getcwd() + "\\static\\files"


@main.route('/')
def home_page():
    return "Hello, World!"


@main.route('/register', methods=['POST'])
def register_page():
    data = request.json
    if 'password' in data:
        # Retrieve the password from the JSON data
        email = data['email']
        user = User.query.filter_by(email=email).first()
        if user:
            return jsonify({'message': 'Email already exists'}), 400
        password = data['password']
        password_bytes = password.encode('utf-8')
        password_hash_bytes = bcrypt.hashpw(password_bytes, bcrypt.gensalt())
        password_hash = password_hash_bytes.decode('utf-8')
        str_id = str(uuid.uuid4())
        cur_dir = root_directory + '\\' + str_id
        os.mkdir(cur_dir)
        user = User(email=email, password_hash=password_hash, id=str_id, current_directory=cur_dir)
        db.session.add(user)
        db.session.commit()
        return make_response(jsonify({'message': 'User created'}), 201)
    else:
        return make_response(jsonify({'message': 'Password field is required'}), 400)


@main.route('/login', methods=['GET', 'POST'])
def login_page():
    if request.method == 'POST':
        data = request.json
        email = data['email']
        password = data['password']
        user = User.query.filter_by(email=email).first()
        if user:
            # check if the user is already logged in
            if 'user_id' in session:
                return make_response(jsonify({'message': 'User is already logged in'}), 400)
            # check if the password is correct
            if bcrypt.checkpw(password.encode('utf-8'), user.password_hash.encode('utf-8')):
                session['user_id'] = user.id
                return make_response(jsonify({'user_id': str(user.id)}), 200)
            else:
                return make_response(jsonify({'message': 'Invalid credentials'}), 400)
        else:
            return make_response(jsonify({'message': 'Invalid credentials'}), 400)
    else:
        return make_response(jsonify({'message': 'Invalid request method'}), 400)


@main.route('/logout', methods=['GET', 'POST'])
def logout_page():
    data = request.json
    user_id = data['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        session.pop('user_id', None)
        return make_response(jsonify({'message': 'User logged out'}), 200)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/currentDirectory', methods=['GET', 'POST'])
def get_current_directory():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        return make_response(
            jsonify({'current_directory': user.current_directory.replace(root_directory + '\\' + user_id, '')}), 200)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/createDirectory', methods=['GET', 'POST'])
def create_directory():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        data = request.json
        try:
            os.mkdir(os.path.join(user.current_directory, data['name']))
            user.current_directory = user.current_directory + '\\' + data['name']
            db.session.commit()
            cur_dir = user.current_directory.replace(root_directory + '\\' + user_id, '')
            print(cur_dir)
            return make_response(jsonify({'current_directory': cur_dir}), 200)
        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/changeDirectory', methods=['GET', 'POST'])
def change_directory():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        data = request.json
        try:
            if data['name'] == '..':
                if user.current_directory == root_directory + '\\' + user.id:
                    return make_response(jsonify({'message': 'Already in root directory'}), 400)
                user.current_directory = os.path.dirname(user.current_directory)
            else:
                if not os.path.exists(os.path.join(user.current_directory, data['name'])):
                    return make_response(jsonify({'message': 'Directory does not exist'}), 400)
                user.current_directory = user.current_directory + "\\" + data['name']
            db.session.commit()
            cur_dir = user.current_directory.replace(root_directory + '\\' + user_id, '')
            return make_response(jsonify({'current_directory': cur_dir}), 200)
        except Exception as e:
            return make_response(jsonify({'message': 'A' + str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/deleteDirectory', methods=['GET', 'POST'])
def delete_directory():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        data = request.json
        try:
            os.rmdir(os.path.join(user.current_directory, data['name']))
            db.session.commit()
            cur_dir = user.current_directory.replace(root_directory + '\\' + user_id, '')
            return make_response(jsonify({'current_directory': cur_dir}), 200)
        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/listDirectory', methods=['GET', 'POST'])
def list_directory():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        try:
            files = os.listdir(user.current_directory)
            for i in range(len(files)):
                if os.path.isdir(os.path.join(user.current_directory, files[i])):
                    files[i] = files[i] + "dir"
            return make_response(jsonify({'files': files}), 200)
        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/deleteFile', methods=['GET', 'POST'])
def delete_file():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        data = request.json
        try:
            file_path = os.path.join(user.current_directory, data['name'])
            if file_path.endswith('dir'):
                os.rmdir(file_path)
                return make_response(jsonify({'message': 'Folder deleted successfully'}), 200)
            else:
                os.remove(file_path)
                return make_response(jsonify({'message': 'File deleted successfully'}), 200)

        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)

"""
Future<void> _uploadFile() async {
    var ip = dotenv.env['API_URL'];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      withReadStream: true,
    );
    if (result != null) {
      var url = Uri.parse('$ip/uploadFile');

      try {
        var request = http.MultipartRequest('POST', url);

        // Add user_id field to the request
        request.fields['user_id'] = widget.user_id;

        // Add the picked file to the request
        var pickedFile = result.files.single;
        if (pickedFile.readStream != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            pickedFile.path!,
          ));

          var response = await request.send();

          if (response.statusCode == 200) {
            // Handle successful response
            setState(() {
              // Update UI if needed
              currentDirectory = currentDirectory;
            });
          } else {
            print('Request failed with status: ${response.statusCode}.');
          }
        } else {
          print('File read stream is null.');
        }
      } catch (e) {
        print('Request failed with error: $e.');
      }
    }
  }
"""

@main.route('/uploadFile', methods=['GET', 'POST'])
def upload_file():
    user_id = request.form['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        try:
            file = request.files['file']
            file.save(os.path.join(user.current_directory, file.filename))
            return make_response(jsonify({'message': 'File uploaded successfully'}), 200)
        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)


@main.route('/downloadFile', methods=['GET', 'POST'])
def download_file():
    user_id = request.json['user_id']
    user = User.query.filter_by(id=user_id).first()
    if user:
        try:
            file_path = os.path.join(user.current_directory, request.json['name'])
            return make_response(send_file(file_path), 200)
        except Exception as e:
            return make_response(jsonify({'message': str(e)}), 400)
    else:
        return make_response(jsonify({'message': 'User not found'}), 404)
