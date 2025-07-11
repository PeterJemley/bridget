# SwiftData Schema & Persistence Testing Checklist

This checklist covers essential techniques and patterns to ensure your SwiftData schema and code are robust, performant, and production-ready.

---

## 1. Set Up an In-Memory Test Environment

Use an in-memory store for fast, isolated, and repeatable tests:

```swift
import XCTest
import SwiftData

class MyModelTests: XCTestCase {
  var container: ModelContainer!

  override func setUp() throws {
    container = try ModelContainer(
      for: [Person.self, Task.self],
      configurations: [.default: .inMemory]
    )
  }

  override func tearDown() {
    container = nil
  }
}
```
- **Why?** No disk I/O, no leftover state between tests.
- **Tip:** For SQLite introspection, use `.persistent(url:)` with a temp file and clean up after.

---

## 2. CRUD Operation Tests

For every @Model type, exercise Create, Read, Update, Delete:

```swift
func testCreateReadUpdateDeletePerson() throws {
  let context = container.mainContext

  // Create
  let alice = Person(name: "Alice", age: 30)
  context.insert(alice)
  try context.save()

  // Read
  let results = try context.fetch(Person.self)
  XCTAssertEqual(results.count, 1)
  XCTAssertEqual(results.first?.name, "Alice")

  // Update
  alice.age = 31
  try context.save()
  XCTAssertEqual(try context.fetch(Person.self).first?.age, 31)

  // Delete
  context.delete(alice)
  try context.save()
  XCTAssertTrue((try context.fetch(Person.self)).isEmpty)
}
```
- **Granularity:** Test each field and relationship.
- **Edge cases:** Empty strings, zero values, maximum lengths.

---

## 3. Relationship & Cascade Tests

If you have one-to-many or many-to-many, ensure inserts and deletes cascade correctly:

```swift
func testTaskCascadeDeleteOnPersonRemoval() throws {
  let context = container.mainContext
  let bob = Person(name: "Bob", age: 25)
  let task1 = Task(title: "T1", owner: bob)
  context.insert(bob)
  try context.save()

  context.delete(bob)
  try context.save()
  XCTAssertTrue((try context.fetch(Task.self)).isEmpty, "Tasks should be removed when owner is deleted")
}
```
- **Verify:**
  - Orphaned records aren’t left behind.
  - Inverse relationships stay in sync.

---

## 4. Schema Validation via SQL Introspection

Open the SQLite backing store and run PRAGMA queries:

```swift
// (In a test where you’re using a file‐backed store)
let storeURL = container.persistentStoreURL(for: .default)!
let db = try SQLiteDatabase.open(storeURL.path)
let columns = try db.prepare("PRAGMA table_info(Person)")
XCTAssertTrue(columns.contains { $0["name"] as? String == "age" })
```
- **Checks:**
  - All expected tables exist.
  - Columns’ types and nullability match your model.
  - Indexes and constraints are present (if you added custom ones).

---

## 5. Migration Tests

Whenever you change your model, simulate migrating from old → new:

1. Build v1 binary and use it to write a store with known data.
2. Load that store in your v2 test container and verify:
   - No data loss.
   - Default values for new properties.
   - Schema changed as expected.

```swift
func testMigrationFromV1toV2() throws {
  // (Set up v1 store on disk with sample data.)
  let oldStore = try makeV1Store()
  // Load in a container configured with the new model.
  let newContainer = try ModelContainer(
    for: [Person.self /* now with new fields */],
    configurations: [.default: .persistent(url: oldStore.url)]
  )
  // Fetch and assert both old and new fields.
}
```

---

## 6. Concurrency & Threading

SwiftData contexts are actor-isolated. Test that background work merges correctly:

```swift
func testBackgroundContextMerge() throws {
  let main = container.mainContext
  let bg = try container.makeBackgroundContext()

  let exp = expectation(description: "Background save")
  bg.perform {
    let charlie = Person(name: "Charlie", age: 40)
    bg.insert(charlie)
    try! bg.save()
    exp.fulfill()
  }
  waitForExpectations(timeout: 1)

  // The main context should see Charlie after merge:
  XCTAssertEqual((try main.fetch(Person.self)).count, 1)
}
```
- **Tip:** Write tests where both contexts simultaneously modify the same object to uncover merge conflicts.

---

## 7. Performance Tests

Use measure blocks in XCTest to track CRUD and fetch times as your dataset grows:

```swift
func testFetchPerformance() throws {
  let context = container.mainContext
  // Seed 10_000 objects
  for i in 0..<10_000 {
    context.insert(Person(name: "P\(i)", age: i))
  }
  try context.save()

  measure {
    _ = try! context.fetch(Person.self, where: \.age > 5000)
  }
}
```
- **Watch for regressions** as you add indexes or change predicates.
- **Fail if average fetch time exceeds your SLA.**

---

## 8. Error & Constraint Handling

If you’ve added validation or unique constraints, assert that violations throw:

```swift
func testUniqueEmailConstraint() throws {
  let context = container.mainContext
  let p1 = User(name: "U1", email: "dup@mail.com")
  let p2 = User(name: "U2", email: "dup@mail.com")
  context.insert(p1)
  try context.save()
  context.insert(p2)
  XCTAssertThrowsError(try context.save()) { err in
    // inspect error for constraint violation
  }
}
```

---

## 9. Integration & UI-Level Tests

Wrap your data layer behind protocols so you can inject either:
- A real ModelContainer (for integration tests)
- A mock or in-memory fake (for fast unit tests)

Then drive your views with XCTest + XCUIApplication:

```swift
func testListViewShowsNewItem() {
  let app = XCUIApplication()
  app.launchArguments = ["-useInMemoryStore"]
  app.launch()
  app.buttons["Add Person"].tap()
  XCTAssertTrue(app.staticTexts["Alice"].exists)
}
```

---

## 10. Continuous Integration
- Run your full test suite on every PR (macOS + iOS simulators).
- Fail fast on migration issues.
- Track test coverage and enforce a minimum threshold on your data layer.
- Automate generating an in-memory coverage report so you can watch for untested models or methods.

---

## Summary

By combining unit tests (CRUD, relationships, constraints), schema introspection, migration simulations, concurrency checks, performance benchmarks, error-case assertions, UI/integration tests, and CI enforcement, you’ll gain the granular visibility you need to ship a SwiftData-backed app with confidence. 