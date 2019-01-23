module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class OutgoingExchangeLineItemFee < UsingEnterpriseFee
          def fee_calculated_on_transfer_through_name
            context.data["outgoing_exchange_enterprise_name"]
          end

          def tax_category_name
            context.data["tax_category_name"] || context.data["product_tax_category_name"]
          end
        end
      end
    end
  end
end
