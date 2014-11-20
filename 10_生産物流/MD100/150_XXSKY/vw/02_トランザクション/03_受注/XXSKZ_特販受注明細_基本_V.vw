/*************************************************************************
 * 
 * View  Name      : XXSKZ_���̎󒍖���_��{_V
 * Description     : XXSKZ_���̎󒍖���_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���̎󒍖���_��{_V
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
-- 2009/12/25 T.Yoshimoto Mod Start
--      , xhkv.�i�ږ�                               �i�ړE�v
      ,(select xhkv.�i�ږ�
        from XXSKZ_�i�ڃ}�X�^_��{_V   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) �i�ړE�v
-- 2009/12/25 T.Yoshimoto Mod End
      , oola.order_quantity_uom                   �P��
      , oola.ordered_quantity                     ����
      , oola.attribute8                           "���Ԏw��iFrom�j"
      , oola.attribute9                           "���Ԏw��iTo�j"
      , oola.attribute7                           ���l
      , oola.attribute4                           �����\���
      , oola.attribute6                           �q�R�[�h
-- 2009/12/25 T.Yoshimoto Mod Start
--      , xhkv.�P�[�X����                           ����
--      , xhwkv.���i�敪                            ���i�敪
--      , xhwkv.���i�敪��                          ���i�敪��
--      , xhwkv.�{�Џ��i�敪                        �{�Џ��i�敪
--      , xhwkv.�{�Џ��i�敪��                      �{�Џ��i�敪��
--      , xhwkv.�i�ڋ敪                            �i�ڋ敪
--      , xhwkv.�i�ڋ敪��                          �i�ڋ敪��
      ,(select xhkv.�P�[�X����
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) ����
      ,(select xhwkv.���i�敪
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) ���i�敪
      ,(select xhwkv.���i�敪��
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) ���i�敪��
      ,(select xhwkv.�{�Џ��i�敪
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) �{�Џ��i�敪
      ,(select xhwkv.�{�Џ��i�敪��
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) �{�Џ��i�敪��
      ,(select xhwkv.�i�ڋ敪
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) �i�ڋ敪
      ,(select xhwkv.�i�ڋ敪��
        from xxskz_�i�ڃJ�e�S������_��{_v   xhwkv
        where xhwkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.�K�p�J�n��
                            AND xhwkv.�K�p�I����
       ) �i�ڋ敪��
--      , xhkv.���i���                             ���i���
--      , xhkv.���i��ʖ�                           ���i��ʖ�
--      , xhkv.�d�ʗe�ϋ敪                         �d�ʗe�ϋ敪
--      , xhkv.�d�ʗe�ϋ敪��                       �d�ʗe�ϋ敪��
--      , xhkv.�d��                                 �d��
--      , xhkv.�e��                                 �e��
      ,(select xhkv.���i���
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) ���i���
      ,(select xhkv.���i��ʖ�
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) ���i��ʖ�
      ,(select xhkv.�d�ʗe�ϋ敪
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) �d�ʗe�ϋ敪
      ,(select xhkv.�d�ʗe�ϋ敪��
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) �d�ʗe�ϋ敪��
      ,(select xhkv.�d��
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) �d��
      ,(select xhkv.�e��
        from xxskz_�i�ڃ}�X�^_��{_v   xhkv
        where xhkv.�i�ڃR�[�h = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.�K�p�J�n��
                            AND xhkv.�K�p�I����
       ) �e��
-- 2009/12/25 T.Yoshimoto Mod End
FROM
        oe_order_headers_all            ooha  --�󒍃w�b�_�e�[�u��
      , oe_order_lines_all              oola  --�󒍖��׃e�[�u��
      , mtl_secondary_inventories       msi
-- 2009/12/25 T.Yoshimoto Del Start
--      , xxsky_�i�ڃ}�X�^_��{_v         xhkv
--      , xxsky_�i�ڃJ�e�S������_��{_v   xhwkv
-- 2009/12/25 T.Yoshimoto Del End
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
-- 2009/12/25 T.Yoshimoto Del Start
--AND   oola.ordered_item = xhkv.�i�ڃR�[�h
--AND   ooha.request_date BETWEEN xhkv.�K�p�J�n��
--                            AND xhkv.�K�p�I����
--AND   oola.ordered_item = xhwkv.�i�ڃR�[�h
--AND   ooha.request_date BETWEEN xhwkv.�K�p�J�n��
--                            AND xhwkv.�K�p�I����
-- 2009/12/25 T.Yoshimoto Del End
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
/
COMMENT ON TABLE APPS.XXSKZ_���̎󒍖���_��{_V IS 'SKYLINK�p ���̎󒍖���(��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���׃^�C�v IS '���׃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�˗�No IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�ۊǏꏊ�R�[�h IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�ۊǏꏊ IS '�ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�󒍔ԍ� IS '�󒍔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�o�ח\��� IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�[�i�\��� IS '�[�i�\���'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�󒍕i�� IS '�󒍕i��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�i�ړE�v IS '�i�ړE�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V."���Ԏw��iFrom�j" IS '���Ԏw��iFrom�j'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V."���Ԏw��iTo�j" IS '���Ԏw��iTo�j'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���l IS '���l'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�����\��� IS '�����\���'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�q�R�[�h IS '�q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���� IS '�l��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�{�Џ��i�敪 IS '�{�Џ��i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�{�Џ��i�敪�� IS '�{�Џ��i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���i��� IS '���i���'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.���i��ʖ� IS '���i��ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�d�ʗe�ϋ敪 IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�d�ʗe�ϋ敪�� IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍖���_��{_V.�e�� IS '�e��'
/

