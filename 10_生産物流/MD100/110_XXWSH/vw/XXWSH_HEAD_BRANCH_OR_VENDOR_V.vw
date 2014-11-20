CREATE OR REPLACE VIEW xxwsh_head_branch_or_vendor_v
(
  biz_type,
  party_vendor_number,
  party_vendor_short_name,
  category
)
AS
  SELECT '1', --'�o�� ���_'
         xcav.party_number,
         xcav.party_short_name,
         '���_'
-- ***** #1648 2009/10/7 S *****
--  FROM xxcmn_cust_accounts_v xcav
  FROM xxcmn_cust_accounts3_v xcav
-- ***** #1648 2009/10/7 E *****
  WHERE xcav.customer_class_code = '1'
  UNION
  SELECT '2', --'�x�� �����'
         xvv.segment1,
         xvv.vendor_short_name,
         '�����'
  FROM xxcmn_vendors_v xvv
;
--
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.biz_type                IS '�Ɩ����';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_number     IS '�Ǌ����_/�����';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.party_vendor_short_name IS '�Ǌ����_/����於��';
COMMENT ON COLUMN xxwsh_head_branch_or_vendor_v.category                IS '����';
--
COMMENT ON TABLE  xxwsh_head_branch_or_vendor_v IS '�Ǌ����_/�����VIEW';
