/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_INVENTORY_APPROVE_V
 * Description : �I�����F��ʃr���[
 * Version     : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   H.Sasaki         �V�K�쐬
 *  2009/05/13    1.1   T.Nakamura       [T1_0877]CREATE���̃Z�~�R�������폜
 *  2009/05/22    1.2   T.Nakamura       [T1_1150]���_�R�[�h�ɂ��i���������폜
 *  2009/07/24    1.3   H.Sasaki         [0000830]�I���Ǘ��̒��o�������C��
 *  2009/07/29    1.4   N.Abe            [0000878]���o�����A�o�͏����C��
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOI_INVENTORY_APPROVE_V(
   INVENTORY_SEQ
  ,BASE_CODE
  ,BASE_NAME
  ,SUBINVENTORY_CODE
  ,SUBINVENTORY_NAME
  ,DISABLE_DATE
  ,INVENTORY_YEAR_MONTH
  ,INVENTORY_DATE
  ,INVENTORY_STATUS
  ,INVENTORY_STATUS_NAME
  ,CREATED_BY
  ,CREATION_DATE
  ,LAST_UPDATED_BY
  ,LAST_UPDATE_DATE
  ,LAST_UPDATE_LOGIN
) AS 
-- == 2009/07/24 V1.3 Modified START =============================================================
--SELECT   ici.inventory_seq                inventory_seq             -- �I��SEQ
--        ,msi.attribute7                   base_code                 -- ���_�R�[�h
--        ,hca.account_name                 base_name                 -- ���_����
--        ,msi.secondary_inventory_name     subinventory_code         -- �ۊǏꏊ�R�[�h
--        ,msi.description                  subinventory_name         -- �ۊǏꏊ����
--        ,msi.disable_date                 disable_date              -- ������
--        ,ici.inventory_year_month         inventory_year_month      -- �N��
--        ,ici.inventory_date               inventory_date            -- �I����
--        ,ici.inventory_status             inventory_status          -- �I���X�e�[�^�X
--        ,flv.meaning                      inventory_status_name     -- �I���X�e�[�^�X����
--        ,ici.created_by                   created_by                -- �쐬��
--        ,ici.creation_date                creation_date             -- �쐬����
--        ,ici.last_updated_by              last_updated_by           -- �ŏI�X�V��
--        ,ici.last_update_date             last_update_date          -- �ŏI�X�V����
--        ,ici.last_update_login            last_update_login         -- �ŏI�X�V���O�C����
--FROM     mtl_secondary_inventories        msi                       -- �ۊǏꏊ�}�X�^
--        ,hz_cust_accounts                 hca                       -- �ڋq�}�X�^
--        ,fnd_lookup_values                flv                       -- �Q�ƃ^�C�v
--        ,( SELECT  xic.inventory_seq                                      inventory_seq             -- �I��SEQ
--                  ,xic.inventory_year_month                               inventory_year_month      -- �N��
--                  ,xic.inventory_date                                     inventory_date            -- �I����
--                  ,NVL(xic.inventory_status, 0)                           inventory_status          -- �I���X�e�[�^�X
--                  ,xic.inventory_kbn                                      inventory_kbn             -- �I���敪
--                  ,msi_in.attribute7                                      base_code                 -- ���_�R�[�h
--                  ,msi_in.secondary_inventory_name                        subinventory_code         -- ���́i�ۊǏꏊ�R�[�h�j
--                  ,msi_in.organization_id                                 organization_id           -- �g�DID
--                  ,NVL(xic.created_by       ,msi_in.created_by       )    created_by                -- �쐬��
--                  ,NVL(xic.creation_date    ,msi_in.creation_date    )    creation_date             -- �쐬����
--                  ,NVL(xic.last_updated_by  ,msi_in.last_updated_by  )    last_updated_by           -- �ŏI�X�V��
--                  ,NVL(xic.last_update_date ,msi_in.last_update_date )    last_update_date          -- �ŏI�X�V����
--                  ,NVL(xic.last_update_login,msi_in.last_update_login)    last_update_login         -- �ŏI�X�V���O�C����
--           FROM    xxcoi_inv_control                  xic                 -- �I���Ǘ��e�[�u��
--                  ,mtl_secondary_inventories          msi_in              -- �ۊǏꏊ�}�X�^
--           WHERE   msi_in.organization_id             =   xxcoi_common_pkg.get_organization_id('S01')
---- == 2009/05/22 V1.2 Deleted START =============================================================
----           AND     msi_in.attribute7                  =   xic.base_code(+)
---- == 2009/05/22 V1.2 Deleted END   =============================================================
--           AND     msi_in.secondary_inventory_name    =   xic.subinventory_code(+)
--         )                                ici                       -- �I���Ǘ����
--WHERE   msi.organization_id             = ici.organization_id
--AND     msi.attribute7                  = hca.account_number
--AND     hca.customer_class_code         = '1'
---- == 2009/05/22 V1.2 Deleted START =============================================================
----AND     msi.attribute7                  = ici.base_code
---- == 2009/05/22 V1.2 Deleted END   =============================================================
--AND     msi.secondary_inventory_name    = ici.subinventory_code
--AND     (   ici.inventory_kbn  = '2'
--         OR ici.inventory_kbn IS NULL
--        )
--AND     msi.attribute1 <> '5'
--AND     msi.attribute1 <> '8'
--AND     flv.lookup_type                 = 'XXCOI1_INV_STATUS_F'
--AND     flv.lookup_code                 = ici.inventory_status
--AND     flv.language                    = USERENV('LANG')
--
SELECT   ici.inventory_seq                inventory_seq             -- �I��SEQ
        ,msi.attribute7                   base_code                 -- ���_�R�[�h
        ,hca.account_name                 base_name                 -- ���_����
        ,msi.secondary_inventory_name     subinventory_code         -- �ۊǏꏊ�R�[�h
        ,msi.description                  subinventory_name         -- �ۊǏꏊ����
        ,msi.disable_date                 disable_date              -- ������
        ,ici.inventory_year_month         inventory_year_month      -- �N��
        ,ici.inventory_date               inventory_date            -- �I����
        ,ici.inventory_status             inventory_status          -- �I���X�e�[�^�X
        ,flv.meaning                      inventory_status_name     -- �I���X�e�[�^�X����
        ,ici.created_by                   created_by                -- �쐬��
        ,ici.creation_date                creation_date             -- �쐬����
        ,ici.last_updated_by              last_updated_by           -- �ŏI�X�V��
        ,ici.last_update_date             last_update_date          -- �ŏI�X�V����
        ,ici.last_update_login            last_update_login         -- �ŏI�X�V���O�C����
FROM     mtl_secondary_inventories        msi                       -- �ۊǏꏊ�}�X�^
        ,hz_cust_accounts                 hca                       -- �ڋq�}�X�^
        ,fnd_lookup_values                flv                       -- �Q�ƃ^�C�v
        ,(
          SELECT  xic.inventory_seq                                      inventory_seq             -- �I��SEQ
                 ,xic.inventory_year_month                               inventory_year_month      -- �N��
                 ,xic.inventory_date                                     inventory_date            -- �I����
                 ,NVL(xic.inventory_status, 0)                           inventory_status          -- �I���X�e�[�^�X
                 ,sub_msi.attribute7                                     base_code                 -- ���_�R�[�h
                 ,sub_msi.secondary_inventory_name                       subinventory_code         -- ���́i�ۊǏꏊ�R�[�h�j
                 ,sub_msi.organization_id                                organization_id           -- �g�DID
                 ,NVL(xic.created_by       ,sub_msi.created_by       )   created_by                -- �쐬��
                 ,NVL(xic.creation_date    ,sub_msi.creation_date    )   creation_date             -- �쐬����
                 ,NVL(xic.last_updated_by  ,sub_msi.last_updated_by  )   last_updated_by           -- �ŏI�X�V��
                 ,NVL(xic.last_update_date ,sub_msi.last_update_date )   last_update_date          -- �ŏI�X�V����
                 ,NVL(xic.last_update_login,sub_msi.last_update_login)   last_update_login         -- �ŏI�X�V���O�C����
          FROM    (SELECT    xic_main.inventory_seq
                            ,xic_main.inventory_year_month
                            ,xic_main.subinventory_code
                            ,xic_main.inventory_date
                            ,xic_main.inventory_status
                            ,xic_main.created_by
                            ,xic_main.creation_date
                            ,xic_main.last_updated_by
                            ,xic_main.last_update_date
                            ,xic_main.last_update_login
                   FROM      xxcoi_inv_control     xic_main
                            ,(SELECT    MAX(xic.inventory_date)   inventory_date
                                       ,xic.base_code             base_code
                                       ,xic.subinventory_code     subinventory_code
                              FROM      xxcoi_inv_control        xic
-- == 2009/07/29 V1.4 Added START =============================================================
                                       ,(SELECT MIN(TO_CHAR(oap.period_start_date, 'YYYYMM')) period_date
                                         FROM   org_acct_periods  oap
                                         WHERE  oap.organization_id  = xxcoi_common_pkg.get_organization_id('S01')
                                         AND    oap.open_flag        = 'Y'
                                        ) oap_sub
-- == 2009/07/29 V1.4 Added END   =============================================================
                              WHERE     xic.inventory_kbn    =   '2'
-- == 2009/07/29 V1.4 Added START =============================================================
                              AND       xic.inventory_year_month = oap_sub.period_date
-- == 2009/07/29 V1.4 Added END   =============================================================
                              GROUP BY  xic.inventory_year_month
                                       ,xic.base_code
                                       ,xic.subinventory_code
                             ) xic_sub
                   WHERE     xic_main.inventory_date    =   xic_sub.inventory_date
                   AND       xic_main.base_code         =   xic_sub.base_code
                   AND       xic_main.subinventory_code =   xic_sub.subinventory_code
                   AND       xic_main.inventory_kbn     =   '2'
                  )                                   xic                 -- �I���Ǘ��e�[�u��
                 ,mtl_secondary_inventories           sub_msi             -- �ۊǏꏊ�}�X�^
          WHERE   sub_msi.organization_id             =   xxcoi_common_pkg.get_organization_id('S01')
          AND     sub_msi.secondary_inventory_name    =   xic.subinventory_code(+)
         )                                ici                       -- �I���Ǘ����
WHERE   msi.organization_id             = ici.organization_id
AND     msi.attribute7                  = hca.account_number
AND     hca.customer_class_code         = '1'
AND     msi.secondary_inventory_name    = ici.subinventory_code
-- == 2009/07/29 V1.4 Added START =============================================================
AND     msi.attribute13 <> '7'
-- == 2009/07/29 V1.4 Added END   =============================================================
AND     msi.attribute1 <> '5'
AND     msi.attribute1 <> '8'
AND     flv.lookup_type                 = 'XXCOI1_INV_STATUS_F'
AND     flv.lookup_code                 = ici.inventory_status
AND     flv.language                    = USERENV('LANG')
-- == 2009/07/24 V1.3 Modified END   =============================================================
/
COMMENT ON TABLE  XXCOI_INVENTORY_APPROVE_V                       IS '�I�����F��ʃr���[';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_SEQ         IS '�I��SEQ';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.BASE_CODE             IS '���_�R�[�h';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.BASE_NAME             IS '���_����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.SUBINVENTORY_CODE     IS '�ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.SUBINVENTORY_NAME     IS '�ۊǏꏊ����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.DISABLE_DATE          IS '������';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_YEAR_MONTH  IS '�N��';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_DATE        IS '�I����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_STATUS      IS '�I���X�e�[�^�X';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_STATUS_NAME IS '�I���X�e�[�^�X����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.CREATED_BY            IS '�쐬��';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.CREATION_DATE         IS '�쐬����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATED_BY       IS '�ŏI�X�V��';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATE_DATE      IS '�ŏI�X�V����';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATE_LOGIN     IS '�ŏI�X�V���O�C����';
/
