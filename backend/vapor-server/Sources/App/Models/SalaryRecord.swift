import Fluent
import Foundation

/// One valid row of the ingested spreadsheet — a public position and its
/// remuneration, plus all non-mandatory source columns preserved in `extraFields`.
final class SalaryRecord: Model, @unchecked Sendable {
    static let schema = "salary_records"

    @ID(key: .id) var id: UUID?
    @Parent(key: "dataset_id") var dataset: Dataset
    @Field(key: "position_title") var positionTitle: String
    @Field(key: "institution") var institution: String
    @Field(key: "salary_amount") var salaryAmount: Double
    @Field(key: "source_row_number") var sourceRowNumber: Int
    @Field(key: "extra_fields") var extraFields: ExtraFields

    init() {}

    init(
        datasetID: UUID,
        positionTitle: String,
        institution: String,
        salaryAmount: Double,
        sourceRowNumber: Int,
        extraFields: [LabeledValue]
    ) {
        self.$dataset.id = datasetID
        self.positionTitle = positionTitle
        self.institution = institution
        self.salaryAmount = salaryAmount
        self.sourceRowNumber = sourceRowNumber
        self.extraFields = ExtraFields(extraFields)
    }
}
