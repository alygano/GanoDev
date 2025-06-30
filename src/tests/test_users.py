import json

import pytest

from src.api.users.models import User


def test_add_user(test_app, test_database):
    client = test_app.test_client()
    res = client.post(
        "/users",
        data=json.dumps({"username": "alex", "email": "alex@kali.com"}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 201
    assert "alex@kali.com was added!" in data["message"]


def test_add_user_invalid_json(test_app, test_database):
    client = test_app.test_client()
    res = client.post(
        "/users",
        data=json.dumps({}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 400
    assert "Input payload validation failed" in data["message"]


def test_add_user_invalid_json_keys(test_app, test_database):
    client = test_app.test_client()
    res = client.post(
        "/users",
        data=json.dumps({"email": "joy@eskrima.com"}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 400
    assert "Input payload validation failed" in data["message"]


def test_add_user_duplicate_email(test_app, test_database):
    client = test_app.test_client()
    client.post(
        "/users",
        data=json.dumps({"username": "alex", "email": "alex@kali.com"}),
        content_type="application/json",
    )
    res = client.post(
        "/users",
        data=json.dumps({"username": "alex", "email": "alex@kali.com"}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 400
    assert "Sorry. That email already exists." in data["message"]


def test_single_user(test_app, test_database, add_user):
    user = add_user("randy", "randy@arnis.com")
    client = test_app.test_client()
    res = client.get(f"/users/{user.id}")
    data = json.loads(res.data.decode())

    assert res.status_code == 200
    assert "randy" in data["username"]
    assert "randy@arnis.com" in data["email"]


def test_single_user_incorrect_id(test_app, test_database):
    client = test_app.test_client()
    res = client.get("/users/999")
    data = json.loads(res.data.decode())

    assert res.status_code == 404
    assert "User 999 does not exist" in data["message"]


def test_all_users(test_app, test_database, add_user):
    test_database.session.query(User).delete()
    add_user("leila", "leila@eskrima.com")
    add_user("kristian", "kristian@arnis.com")
    client = test_app.test_client()
    res = client.get("/users")
    data = json.loads(res.data.decode())

    assert res.status_code == 200
    assert len(data) == 2
    assert "leila" in data[0]["username"]
    assert "leila@eskrima.com" in data[0]["email"]
    assert "kristian" in data[1]["username"]
    assert "kristian@arnis.com" in data[1]["email"]


def test_remove_user(test_app, test_database, add_user):
    test_database.session.query(User).delete()
    user = add_user("remove user", "remove@user.com")
    client = test_app.test_client()
    res = client.get("/users")
    data = json.loads(res.data.decode())

    assert res.status_code == 200
    assert len(data) == 1

    res_two = client.delete(f"/users/{user.id}")
    data = json.loads(res_two.data.decode())

    assert res_two.status_code == 200
    assert "remove@user.com was removed!" in data["message"]

    res_three = client.get("/users")
    data = json.loads(res_three.data.decode())

    assert res_three.status_code == 200
    assert len(data) == 0


def test_remove_user_incorrect_id(test_app, test_database):
    client = test_app.test_client()
    res = client.delete("/users/999")
    data = json.loads(res.data.decode())

    assert res.status_code == 404
    assert "User 999 does not exist" in data["message"]


def test_update_user(test_app, test_database, add_user):
    user = add_user("update_user", "update@user.com")
    client = test_app.test_client()
    res = client.put(
        f"/users/{user.id}",
        data=json.dumps({"username": "me", "email": "me@user.com"}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 200
    assert f"{user.id} was updated!" in data["message"]

    res_two = client.get(f"/users/{user.id}")
    data = json.loads(res_two.data.decode())

    assert res_two.status_code == 200
    assert "me" in data["username"]
    assert "me@user.com" in data["email"]


# ----- THE FOLLOWING TESTS ARE PARAMETERIZED BELOW -----
# def test_update_user_invalid(test_app, test_database):
#     client = test_app.test_client()
#     res = client.put(
#         "/users/1",
#         data = json.dumps({}),
#         content_type="application/json",
#     )
#     data = json.loads(res.data.decode())

#     assert res.status_code == 400
#     assert "Input payload validation failed" in data["message"]


# def test_update_user_invalid_json_keys(test_app, test_database):
#     client = test_app.test_client()
#     res = client.put(
#         "/users/1",
#         data = json.dumps({}),
#         content_type="application/json",
#     )
#     data = json.loads(res.data.decode())

#     assert res.status_code == 400
#     assert "Input payload validation failed" in data["message"]


# def test_update_user_does_not_exist(test_app, test_database):
#     client = test_app.test_client()
#     res = client.put(
#         "/users/999",
#         data = json.dumps(
#             {
#                 "username": "me",
#                 "email": "me@user.com"
#             }
#         ),
#         content_type="application/json",
#     )
#     data = json.loads(res.data.decode())

#     assert res.status_code == 404
#     assert "User 999 does not exist" in data["message"]


@pytest.mark.parametrize(
    "user_id, payload, status_code, message",
    [
        [1, {}, 400, "Input payload validation failed"],
        [1, {"email": "me@user.com"}, 400, "Input payload validation failed"],
        [
            999,
            {"username": "me", "email": "me@user.com"},
            404,
            "User 999 does not exist",
        ],
    ],
)
def test_update_user_invalid(
    test_app, test_database, user_id, payload, status_code, message
):
    client = test_app.test_client()
    res = client.put(
        f"/users/{user_id}", data=json.dumps(payload), content_type="application/json,"
    )
    data = json.loads(res.data.decode())

    assert res.status_code == status_code
    assert message in data["message"]


def test_update_user_duplicate_email(test_app, test_database, add_user):
    add_user("me", "me@user.com")
    user = add_user("other", "other@notuser.com")
    client = test_app.test_client()
    res = client.put(
        f"/users/{user.id}",
        data=json.dumps({"username": "other", "email": "other@notuser.com"}),
        content_type="application/json",
    )
    data = json.loads(res.data.decode())

    assert res.status_code == 400
    assert "Sorry. That email already exists." in data["message"]
