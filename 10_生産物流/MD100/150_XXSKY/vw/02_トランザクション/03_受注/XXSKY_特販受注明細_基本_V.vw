CREATE OR REPLACE VIEW APPS.XXSKY_���̎󒍖���_��{_V
(
   ���׃^�C�v
  ,����
  ,�˗�No
  ,�ۊǏꏊ�R�[�h
  ,�ۊǏꏊ
  ,�󒍔ԍ�
  ,�o�ח\���
  ,�[�i�\���
  ,�󒍕i��
  ,�i�ړE�v
  ,�P��
  ,����
  ,"���Ԏw��iFrom�j"
  ,"���Ԏw��iTo�j"
  ,���l
  ,�����\���
  ,�q�R�[�h
  ,����
  -- �R�R����͈�
  ,���i�敪
  ,���i�敪��
  ,�{�Џ��i�敪
  ,�{�Џ��i�敪��
  ,�i�ڋ敪
  ,�i�ڋ敪��
  ,���i���
  ,���i��ʖ�
  ,�d�ʗe�ϋ敪
  ,�d�ʗe�ϋ敪��
  ,�d��
  ,�e��
)
AS
SELECT 
        otttl.description                         ���׃^�C�v
      , oola.line_number                          ����
      , oola.packing_instructions                 �˗�No
      , oola.subinventory                         �ۊǏꏊ�R�[�h
      , msi.description                           �ۊǏꏊ
      , ooha.order_number                         �󒍔ԍ�
      , oola.schedule_ship_date                   �o�ח\���
      , oola.request_date                         �[�i�\���
      , oola.ordered_item                         �󒍕i��
      , xhkv.�i�ږ�                               �i�ړE�v
      , oola.order_quantity_uom                   �P��
      , oola.ordered_quantity                     ����
      , oola.attribute8                           "���Ԏw��iFrom�j"
      , oola.attribute9                           "���Ԏw��iTo�j"
      , oola.attribute7                           ���l
      , oola.attribute4                           �����\���
      , oola.attribute6                           �q�R�[�h
      , xhkv.�P�[�X����                           ����
      -- �R�R����͈�
      , xhwkv.���i�敪                            ���i�敪
      , xhwkv.���i�敪��                          ���i�敪��
      , xhwkv.�{�Џ��i�敪                        �{�Џ��i�敪
      , xhwkv.�{�Џ��i�敪��                      �{�Џ��i�敪��
      , xhwkv.�i�ڋ敪                            �i�ڋ敪
      , xhwkv.�i�ڋ敪��                          �i�ڋ敪��
      , xhkv.���i���                             ���i���
      , xhkv.���i��ʖ�                           ���i��ʖ�
      , xhkv.�d�ʗe�ϋ敪                         �d�ʗe�ϋ敪
      , xhkv.�d�ʗe�ϋ敪��                       �d�ʗe�ϋ敪��
      , xhkv.�d��                                 �d��
      , xhkv.�e��                                 �e��
FROM
        oe_order_headers_all            ooha
      , oe_order_lines_all              oola
      , mtl_secondary_inventories       msi
      , xxsky_�i�ڃ}�X�^_��{_v         xhkv
      , xxsky_�i�ڃJ�e�S������_��{_v   xhwkv
      -- �ڋq���
      , xxcmn_cust_accounts2_v          xca2v
      -- ���׃^�C�v
      , oe_transaction_types_tl         otttl   -- �󒍖��דE�v�p����^�C�v
      -- �c�ƒP��
      , hr_all_organization_units       haou
WHERE
      ooha.header_id      = oola.header_id
AND   ooha.request_date   = oola.request_date
AND   ooha.org_id         = oola.org_id
-- �ۊǏꏊ
AND oola.subinventory     = msi.secondary_inventory_name
AND oola.ship_from_org_id = msi.organization_id
-- �i�ڃ}�X�^
AND   oola.ordered_item = xhkv.�i�ڃR�[�h
AND   ooha.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
AND   oola.ordered_item = xhwkv.�i�ڃR�[�h
AND   ooha.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
-- �ڋq���
AND   ooha.sold_to_org_id       = xca2v.cust_account_id
AND   ooha.request_date BETWEEN xca2v.start_date_active
                            AND xca2v.end_date_active
-- ���׃^�C�v
AND   oola.line_type_id         = otttl.transaction_type_id
AND   otttl.language            = 'JA'
-- ���_�R�[�h�i���̕��w�� �N�C�b�N�R�[�h��`�j
AND   EXISTS (
              SELECT 'x'
              FROM  xxcmn_lookup_values_v xkgv
              WHERE xkgv.lookup_type = 'XXCMN_SALE_SKYLINK_BRANCH'
              AND   xkgv.lookup_code = xca2v.sale_base_code
             )
-- �c�Ƒg�D
AND   haou.type    = 'OU'
AND   haou.name    = 'SALES-OU'
-- �c�� �g�DID
AND   ooha.org_id  = haou.organization_id
;

