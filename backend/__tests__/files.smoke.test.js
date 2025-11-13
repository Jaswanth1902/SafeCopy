process.env.JWT_SECRET =
  process.env.JWT_SECRET || "test_jwt_secret_which_is_long_enough_123456";
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET ||
  "test_jwt_refresh_secret_which_is_long_enough_123456";

const request = require("supertest");
const app = require("../server");
const db = require("../database");
const AuthService = require("../services/authService");

jest.mock("../database");

describe("Files API smoke tests (mocked DB)", () => {
  const userPayload = {
    sub: "user-uuid-1",
    email: "user@example.com",
    role: "user",
  };
  const ownerPayload = {
    sub: "owner-uuid-1",
    email: "owner@example.com",
    role: "owner",
  };
  const userToken = AuthService.generateAccessToken(userPayload, "1h");
  const ownerToken = AuthService.generateAccessToken(ownerPayload, "1h");

  beforeEach(() => {
    jest.resetAllMocks();
  });

  test("register -> login -> upload -> list -> print -> delete flow (mock DB)", async () => {
    // Mock register: first check (no existing user), then insert
    db.query.mockImplementationOnce(() => Promise.resolve({ rows: [] }));
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          {
            id: userPayload.sub,
            email: userPayload.email,
            full_name: null,
            created_at: new Date(),
          },
        ],
      })
    );

    // Call register endpoint
    const regRes = await request(app)
      .post("/api/auth/register")
      .send({ email: userPayload.email, password: "Str0ng!Pass" });
    expect(regRes.statusCode).toBe(201);
    expect(regRes.body).toHaveProperty("accessToken");

    // Mock login select
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          {
            id: userPayload.sub,
            email: userPayload.email,
            password_hash: "$2a$10$fakehash",
            full_name: null,
          },
        ],
      })
    );
    // Mock password compare to return true
    jest.spyOn(AuthService, "comparePassword").mockResolvedValue(true);

    const loginRes = await request(app)
      .post("/api/auth/login")
      .send({ email: userPayload.email, password: "Str0ng!Pass" });
    expect(loginRes.statusCode).toBe(200);
    expect(loginRes.body).toHaveProperty("accessToken");

    // Mock files insert for upload
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          {
            id: "file-uuid-1",
            file_name: "test.pdf",
            file_size_bytes: 11,
            created_at: new Date(),
          },
        ],
      })
    );

    const uploadRes = await request(app)
      .post("/api/upload")
      .set("Authorization", `Bearer ${userToken}`)
      .field("file_name", "test.pdf")
      .field("iv_vector", Buffer.from("iv").toString("base64"))
      .field("auth_tag", Buffer.from("tag").toString("base64"))
      .field("owner_id", ownerPayload.sub)
      .attach("file", Buffer.from("hello world"), "test.pdf");

    expect(uploadRes.statusCode).toBe(201);
    expect(uploadRes.body).toHaveProperty("file_id");

    // Mock list files for owner
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          {
            id: "file-uuid-1",
            file_name: "test.pdf",
            file_size_bytes: 11,
            created_at: new Date(),
            is_printed: false,
            printed_at: null,
          },
        ],
      })
    );

    const listRes = await request(app)
      .get("/api/files")
      .set("Authorization", `Bearer ${ownerToken}`);

    expect(listRes.statusCode).toBe(200);
    expect(Array.isArray(listRes.body.files)).toBe(true);

    // Mock print select
    const fakeFileRow = {
      id: "file-uuid-1",
      file_name: "test.pdf",
      encrypted_file_data: Buffer.from("cipher"),
      file_size_bytes: 11,
      iv_vector: Buffer.from("iv"),
      auth_tag: Buffer.from("tag"),
      created_at: new Date(),
      is_printed: false,
      owner_id: ownerPayload.sub,
    };
    db.query.mockImplementationOnce(() =>
      Promise.resolve({ rows: [fakeFileRow] })
    );

    const printRes = await request(app)
      .get("/api/print/file-uuid-1")
      .set("Authorization", `Bearer ${ownerToken}`);

    expect(printRes.statusCode).toBe(200);
    expect(printRes.body).toHaveProperty("encrypted_file_data");

    // Mock delete check and update
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          {
            id: "file-uuid-1",
            file_name: "test.pdf",
            is_deleted: false,
            owner_id: ownerPayload.sub,
          },
        ],
      })
    );
    db.query.mockImplementationOnce(() =>
      Promise.resolve({
        rows: [
          { id: "file-uuid-1", file_name: "test.pdf", deleted_at: new Date() },
        ],
      })
    );

    const delRes = await request(app)
      .post("/api/delete/file-uuid-1")
      .set("Authorization", `Bearer ${ownerToken}`);

    expect(delRes.statusCode).toBe(200);
    expect(delRes.body.status).toBe("DELETED");
  }, 20000);
});
