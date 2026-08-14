using System.Text.Json;
using Generated;

const string json = """
    {
      "matrix": [[1, null], [2, 3], []],
      "people": [[{"name":"Ada"}], [{"name":"Grace", "age":37}]]
    }
    """;

var model = JsonSerializer.Deserialize<Root>(json)
    ?? throw new InvalidOperationException("Deserialization returned null.");

if (model.Matrix.Count != 3 || model.Matrix[2].Count != 0 || model.Matrix[0][1] is not null)
    throw new InvalidOperationException("Scalar matrix did not deserialize correctly.");
if (model.People[1][0].Name != "Grace" || model.People[1][0].Age != 37)
    throw new InvalidOperationException("Object matrix did not deserialize correctly.");

model.Matrix[0][1] = 42;
model.Matrix.Add([9]);
model.People[0][0].Name = "Augusta";

var serialized = JsonSerializer.Serialize(model);
var roundTrip = JsonSerializer.Deserialize<Root>(serialized)
    ?? throw new InvalidOperationException("Round-trip returned null.");

if (roundTrip.Matrix[0][1] != 42 || roundTrip.Matrix[3][0] != 9 ||
    roundTrip.People[0][0].Name != "Augusta" || roundTrip.People[1][0].Age != 37)
    throw new InvalidOperationException("Matrix round-trip changed the model.");
