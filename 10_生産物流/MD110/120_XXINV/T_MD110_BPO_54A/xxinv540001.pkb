CREATE OR REPLACE PACKAGE BODY xxinv540001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv540001(BODY)
 * Description            : �݌ɏƉ��ʃf�[�^�\�[�X�p�b�P�[�W(BODY)
 * MD.050                 : T_MD050_BPO_540_�݌ɏƉ�Issue1.0.doc
 * MD.070                 : T_MD070_BPO_54A_�݌ɏƉ���Draft1A.doc
 * Version                : 1.1
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    �f�[�^�擾
 *  get_parent_item_id      F   NUM   �e�i��ID�擾
 *  get_attribute5          F   VAR   ��\�q�Ɏ擾
 *  get_organization_id     F   NUM   �݌ɑg�DID�擾
 *  get_inv_stock_vol       F   NUM   �莝�݌ɐ��擾
 *  get_supply_stock_plan   F   NUM   ���ɗ\�萔�擾
 *  get_take_stock_plan     F   NUM   �o�ɗ\�萔�擾
 *  get_subtractable        F   NUM   �����\���擾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/16   1.0   Jun.Komatsu      �V�K�쐬
 *  2008/03/13   1.1   Jun.Komatsu      �ύX�v��#15�A#7�Ή�
 *  2008/03/19   1.2   Jun.Komatsu      �ύX�v��#15�Ή�(2���)
 *  2008/04/18   1.3   Jun.Komatsu      �ύX�v��#43�A#51�Ή�
 *  2008/05/26   1.4   Kazuo.Kumamoto   �ύX�v��##119�Ή�
 *
 *****************************************************************************************/
--
  -- �萔�錾
  cv_status_normal        CONSTANT VARCHAR2(1)  := '0';
  cv_status_warning       CONSTANT VARCHAR2(1)  := '1';
  cv_status_error         CONSTANT VARCHAR2(1)  := '2';
  cv_yes                  CONSTANT VARCHAR2(1)  := 'Y';
  cv_no                   CONSTANT VARCHAR2(1)  := 'N';
  cv_lang_ja              CONSTANT VARCHAR2(2)  := 'JA';
  cv_date_format          CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_type_xxcmn_l05       CONSTANT VARCHAR2(9)  := 'XXCMN_L05';
  cv_type_xxcmn_l06       CONSTANT VARCHAR2(9)  := 'XXCMN_L06';
  cv_type_xxcmn_l07       CONSTANT VARCHAR2(9)  := 'XXCMN_L07';
  cv_type_xxcmn_l08       CONSTANT VARCHAR2(9)  := 'XXCMN_L08';
  cv_type_xxcmn_l03       CONSTANT VARCHAR2(9)  := 'XXCMN_L03';
  cv_type_xxwip_qt_status CONSTANT VARCHAR2(15) := 'XXWIP_QT_STATUS';
  cv_dummy                CONSTANT VARCHAR2(11) := '@@@@@@@@@@@';       -- �_�~�[������
  cv_lot_seihin           CONSTANT VARCHAR2(1)  := '5';                 -- ���i(���b�g�i)
  cv_lot_hanseihin        CONSTANT VARCHAR2(1)  := '4';                 -- �����i(���b�g�i)
  cv_lot_gennryou         CONSTANT VARCHAR2(1)  := '1';                 -- ����(���b�g�i)
  cv_lot_shizai           CONSTANT VARCHAR2(1)  := '2';                 -- ����(�񃍃b�g�i)
  cv_unit_case            CONSTANT VARCHAR2(6)  := '�P�[�X';            -- �P�ʋ敪�F�P�[�X
  cn_zero                 CONSTANT NUMBER       := 0;
  cn_one                  CONSTANT NUMBER       := 1;
  cn_round_effect_num     CONSTANT NUMBER       := 3;                   -- �P�ʊ��Z�L������
  cv_min_date             CONSTANT VARCHAR2(10) := '0000/00/00';
  cv_max_date             CONSTANT VARCHAR2(10) := '9999/99/99';
  cv_type_xxcmn_lotstatus CONSTANT VARCHAR2(16) := 'XXCMN_LOT_STATUS';
  cv_lot_code0            CONSTANT VARCHAR2(1)  := '0';                 -- �񃍃b�g�Ǘ��敪�R�[�h
  cv_lot_code1            CONSTANT VARCHAR2(1)  := '1';                 -- ���b�g�Ǘ��敪�R�[�h
  cn_dummy                CONSTANT NUMBER       := 99999999999;         -- �i���˗�No�_�~�[(11��)
--
  /***********************************************************************************
   * Procedure Name   : blk_ilm_qry
   * Description      : �f�[�^�擾(REF�J�[�\���I�[�v��)
   ***********************************************************************************/
  PROCEDURE blk_ilm_qry(
              ior_ilm_data             IN OUT NOCOPY tbl_ilm_block,
              in_item_id               IN xxcmn_item_mst_v.item_id%TYPE,          --�i��ID
              iv_parent_div            IN VARCHAR2,                               --�e�R�[�h�敪
              in_inventory_location_id IN xxcmn_item_locations_v.inventory_location_id%TYPE,
                                                                                  --�ۊǑq��ID
              iv_deleg_house           IN VARCHAR2,                               --��\�q�ɏƉ�
              iv_ext_warehouse         IN VARCHAR2,                               --�q�ɒ��o�t���O
              iv_item_div_code         IN xxcmn_item_categories_v.segment1%TYPE,  --�i�ڋ敪�R�[�h
              iv_prod_div_code         IN xxcmn_item_categories_v.segment1%TYPE,  --���i�敪�R�[�h
              iv_unit_div              IN VARCHAR2,                               --�P�ʋ敪
              iv_qt_status_code        IN xxwip_qt_inspection.qt_effect1%TYPE,    --�i�����茋��
              id_manu_date_from        IN DATE,                                   --�����N����From
              id_manu_date_to          IN DATE,                                   --�����N����To
              iv_prop_sign             IN ic_lots_mst.attribute2%TYPE,            --�ŗL�L��
              id_consume_from          IN DATE,                                   --�ܖ�����From
              id_consume_to            IN DATE,                                   --�ܖ�����To
              iv_lot_no                IN ic_lots_mst.lot_no%TYPE,                --���b�g��
              iv_register_code         IN xxcmn_item_locations_v.customer_stock_whse%TYPE,
                                                                                  --���`�R�[�h
              id_effective_date        IN DATE,                                   --�L�����t
              iv_ext_show              IN VARCHAR2)                               --�݌ɗL�����\��
  IS
--
    -- �ϐ��錾
    ln_parent_item_id        xxcmn_item_mst_b.parent_item_id%TYPE;                -- �e�i��ID
    lv_attribute5            xxcmn_item_locations_v.frequent_whse%TYPE;           -- ��\�q��
    ln_organization_id       xxcmn_item_locations_v.mtl_organization_id%TYPE;     -- �݌ɑg�DID
    ln_prof_xtt              NUMBER;                                              -- �݌ɏƉ�Ώ�
    lv_prof_xid              VARCHAR2(8);                                         -- �i�ڋ敪
    lv_prof_xpd              VARCHAR2(8);                                         -- ���i�敪
    ld_target_date           DATE;                                                -- �Ώۓ��t
    ln_cnt                   NUMBER;                                              -- �z��̓Y��
    ln_num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE;                  -- �P�[�X����
    ln_cnt_work              NUMBER;                                              -- �W�v�p����
    lv_sort_flag             VARCHAR2(1);                                         -- �\�[�g�t���O
    lv_frequent_whse         xxcmn_item_locations_v.frequent_whse%TYPE;
--
    -- �J�[�\���錾
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_a1 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id         = ln_parent_item_id
      AND    iiim.frequent_whse          = lv_frequent_whse
      AND    iiim.mtl_organization_id    = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_a2 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_a3 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_a4 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_a5 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_a6 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_a7 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_a8 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_a9 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_b1 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_b2 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_b3 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_b4 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_b5 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_b6 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'Y'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_b7 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_b8 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_b9 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_c1 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_c2 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_c3 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_c4 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_c5 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'Y'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_c6 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (��\)�ۊǑq�ɃR�[�h
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (��\)�ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_c7 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_c8 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_c9 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'Y'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_d1 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_d2 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ځA�ۊǑq�ɓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_d3 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i
    --===============================================================
    CURSOR cur_data_d4 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- ��������.�e�R�[�h�敪�l          �� 'N'
    -- ��������.��\�q�ɏƉ�l          �� 'N'
    -- ��������.�q�ɒ��o�t���O�l        �� 'N'
    -- ��������.�i�ځA�q�ɓ��̓p�^�[��  �� �i�ڂ̂ݓ���
    -- ��������.�i�ڋ敪�l              �� ���i�ȊO
    --===============================================================
    CURSOR cur_data_d5 IS
      SELECT iiim.segment1,                                            -- �ۊǑq�ɃR�[�h
             iiim.short_name,                                          -- �ۊǑq�ɖ�
             iiim.inventory_location_id,                               -- �ۊǑq��ID
             iiim.item_id,                                             -- �i��ID
             iiim.item_no,                                             -- �i�ڃR�[�h
             iiim.item_short_name,                                     -- �i�ږ�
             NVL(iiim.num_of_cases, cn_one),                           -- �P�[�X����
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ���b�gNo
             iiim.lot_id,                                              -- ���b�gID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- �����N����(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- �ܖ�����(DFF3)
             iiim.attribute2,                                          -- �ŗL�L��(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- ����[����(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- �ŏI�[����(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- �݌ɓ���(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- �݌ɒP��(DFF7)
             iiim.attribute8,                                          -- �󕥐�(DFF8)
             xvv.vendor_short_name,                                    -- �󕥐於
             iiim.attribute9,                                          -- �d���`��(DFF9)
             xlvv_xl5.meaning,                                         -- �d���`�ԓ��e
             iiim.attribute10,                                         -- �����敪(DFF10)
             xlvv_xl6.meaning,                                         -- �����敪���e
             iiim.attribute11,                                         -- �N�x(DFF11)
             iiim.attribute12,                                         -- �Y�n(DFF12)
             xlvv_xl7.meaning,                                         -- �Y�n���e
             iiim.attribute13,                                         -- �^�C�v(DFF13)
             xlvv_xl8.meaning,                                         -- �^�C�v���e
             iiim.attribute14,                                         -- �����N1(DFF14)
             iiim.attribute15,                                         -- �����N2(DFF15)
             iiim.attribute19,                                         -- �����N3(DFF19)
             iiim.attribute16,                                         -- ���Y�`�[�敪(DFF16)
             xlvv_xl3.meaning,                                         -- ���Y�`�[�敪���e
             iiim.attribute17,                                         -- ���C��No(DFF17)
             gr.routing_desc,                                          -- �H���E�v
             iiim.attribute18,                                         -- �E�v(DFF18)
             xlvv_xls.meaning,                                         -- ���b�g�X�e�[�^�X���e
             xqi.qt_inspect_req_no,                                    -- �i�������˗����
             xlvv_xqs.meaning,                                         -- �i�����ʓ��e
             NVL(ili.loct_onhand, cn_zero),                            -- �莝����
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- �莝�݌ɐ�
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �����\��
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- ���ɗ\�萔
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- �o�ɗ\�萔
             iiim.created_by,                                          -- �쐬��
             iiim.creation_date,                                       -- �쐬��
             iiim.last_updated_by,                                     -- �ŏI�X�V��
             iiim.last_update_date,                                    -- �ŏI�X�V��
             iiim.last_update_login,                                   -- �ŏI�X�V���O�C��
             iiim.frequent_whse                                        -- ��\�q��
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.short_name,            -- �ۊǑq�ɖ�
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_short_name,       -- �i�ڗ���
                     ximv.parent_item_id,        -- �e�i��ID
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ximv.num_of_cases,          -- �P�[�X����
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,  -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- ������3
                        xq.qt_effect3                      -- ����3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- ������2
                        xq.qt_effect2                      -- ����2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- ������1
                        xq.qt_effect1                      -- ����1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- �i�������˗����
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- �N�C�b�N�R�[�h(�d���`�ԓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- �N�C�b�N�R�[�h(�����敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- �N�C�b�N�R�[�h(�Y�n���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- �N�C�b�N�R�[�h(�^�C�v���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- �N�C�b�N�R�[�h(���Y�`�[�敪���e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- �N�C�b�N�R�[�h(�i�����ʓ��e)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
             xxcmn_vendors_v            xvv,        -- �d������
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- �H���}�X�^
                    gmd_routings_tl grt             -- �H���}�X�^����
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- ���o����(��ʌ����l)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- ��ʌ����p�^�[���ʂɈقȂ�A�J�[�\�����̒��o�A�\�[�g����
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
  BEGIN
--
    -- �v���t�@�C���l�擾
    ln_prof_xtt := FND_PROFILE.VALUE('XXINV_TARGET_TERM');
    lv_prof_xid := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
    lv_prof_xpd := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- �v���t�@�C�����擾������������A�݌ɏƉ�Ώۓ��t���Z�o
    ld_target_date := TRUNC(SYSDATE) - ln_prof_xtt;
--
    -- �e�i��ID�擾
    IF (iv_parent_div = cv_yes) THEN
      ln_parent_item_id := get_parent_item_id(
                             in_parent_item_id => in_item_id);
    END IF;
--
    -- ��\�q�Ɏ擾
    IF (iv_deleg_house = cv_yes) THEN
      lv_frequent_whse := get_attribute5(
                            in_inventory_location_id => in_inventory_location_id);
    END IF;
--
    -- �݌ɑg�DID�擾
    IF (iv_ext_warehouse = cv_yes) THEN
      ln_organization_id := get_organization_id(
                              in_inventory_location_id => in_inventory_location_id);
    END IF;
--
    -- �ϐ��̏�����
    ln_cnt := 1;
    lv_sort_flag := '0';
--
    -- �J�[�\���̑I��
    IF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a1;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a1>>
      LOOP
        FETCH cur_data_a1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a1>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a1;
--
          -- �z��J�E���^���C���N�������g
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a2;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a2>>
      LOOP
        FETCH cur_data_a2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
--
          -- �P�ʊ��Z����
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a2>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a2;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a3;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a3>>
      LOOP
        FETCH cur_data_a3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a3>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
--
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a3;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a4;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a4>>
      LOOP
        FETCH cur_data_a4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          <<calculation_a4>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a4;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a5;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a5>>
      LOOP
        FETCH cur_data_a5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a5>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a5;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a6;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a6>>
      LOOP
        FETCH cur_data_a6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a6>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a6;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a7;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a7>>
      LOOP
        FETCH cur_data_a7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a7>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- �����񏈗��������R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- �i�[�ςݑ��̃��R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No�U�蒼���̕K�v�L��
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- �����Ƀ��R�[�h�z��Ɋi�[���ꂽ���̃��R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- �z��J�E���^��1���Z
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_a7;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a8;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a8>>
      LOOP
        FETCH cur_data_a8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_a8>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1
                                                           = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- �����񏈗��������R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- �i�[�ςݑ��̃��R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No�U�蒼���̕K�v�L��
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- �����Ƀ��R�[�h�z��Ɋi�[���ꂽ���̃��R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- �z��J�E���^��1���Z
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_a8;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a9;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_a9>>
      LOOP
        FETCH cur_data_a9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b1;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b1>>
      LOOP
        FETCH cur_data_b1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b2;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b2>>
      LOOP
        FETCH cur_data_b2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b3;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b3>>
      LOOP
        FETCH cur_data_b3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b4;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b4>>
      LOOP
        FETCH cur_data_b4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b5;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b5>>
      LOOP
        FETCH cur_data_b5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b6;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b6>>
      LOOP
        FETCH cur_data_b6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b7;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b7>>
      LOOP
        FETCH cur_data_b7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b8;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b8>>
      LOOP
        FETCH cur_data_b8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_b8>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_b8;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b9;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_b9>>
      LOOP
        FETCH cur_data_b9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_b9>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_b9;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c1;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c1>>
      LOOP
        FETCH cur_data_c1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c1>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c1;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c2;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c2>>
      LOOP
        FETCH cur_data_c2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c2>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c2;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c3;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c3>>
      LOOP
        FETCH cur_data_c3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c3>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c3;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c4;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c4>>
      LOOP
        FETCH cur_data_c4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c4>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- ��\�q�ɂɍ��Z(�莝����)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- ��\�q�ɂɍ��Z(�����\��)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- ��\�q�ɂɍ��Z(���ɗ\�萔)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- �i�[�ςݕۊǏꏊ���\�q�ɂɏ�����(��\�ł͂Ȃ��ۊǏꏊ���\�������s�������)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
              ior_ilm_data.DELETE(ln_cnt);
              -- �z��J�E���^��1���Z
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c4;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no)   = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c5;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c5>>
      LOOP
        FETCH cur_data_c5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c5>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- �����񏈗��������R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- �i�[�ςݑ��̃��R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No�U�蒼���̕K�v�L��
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- �����Ƀ��R�[�h�z��Ɋi�[���ꂽ���̃��R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- �z��J�E���^��1���Z
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_c5;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c6;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c6>>
      LOOP
        FETCH cur_data_c6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
--
          <<calculation_c6>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- �����񏈗��������R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- �i�[�ςݑ��̃��R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No�U�蒼���̕K�v�L��
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- �����Ƀ��R�[�h�z��Ɋi�[���ꂽ���̃��R�[�h����\�ƂȂ�ꍇ
                  -- ��\�q�ɂɍ��Z(�莝����)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- ��\�q�ɂɍ��Z(�莝�݌ɐ�)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- ��\�q�ɂɍ��Z(�����\��)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- ��\�q�ɂɍ��Z(���ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- ��\�q�ɂɍ��Z(�o�ɗ\�萔)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- ����擾�������R�[�h���폜(��\�ɍ��Z������)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- �z��J�E���^��1���Z
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_c6;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c7;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c7>>
      LOOP
        FETCH cur_data_c7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c8;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c8>>
      LOOP
        FETCH cur_data_c8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c9;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_c9>>
      LOOP
        FETCH cur_data_c9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d1;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_d1>>
      LOOP
        FETCH cur_data_d1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_d2;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_d2>>
      LOOP
        FETCH cur_data_d2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d3;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_d3>>
      LOOP
        FETCH cur_data_d3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_d4;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_d4>>
      LOOP
        FETCH cur_data_d4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d5;
      -- ���R�[�h�̎擾
      <<fetch_cur_data_d5>>
      LOOP
        FETCH cur_data_d5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- �݌ɗL�����\���ɂ�钊�o���R�[�h�̑I��
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- �P�ʊ��Z����
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- �P�ʊ��Z����END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d5;
    END IF;
--
    IF (lv_sort_flag = '1') THEN
      -- ��v�f���l�߂�
      <<cnt_work_loop>>
      FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
        IF (NOT (ior_ilm_data.EXISTS(ln_cnt_work))) THEN
          <<cnt_next_loop>>
          FOR ln_cnt_next IN (ln_cnt_work + 1) .. ln_cnt LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_next)) THEN
              ior_ilm_data(ln_cnt_work) := ior_ilm_data(ln_cnt_next);
              ior_ilm_data.DELETE(ln_cnt_next);
              EXIT;
            END IF;
          END LOOP cnt_next_loop;
        END IF;
      END LOOP cnt_work_loop;
      -- No�̐U����
      <<renumbering_loop>>
      FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
        IF NOT(ior_ilm_data.EXISTS(ln_cnt_work)) THEN
          EXIT;
        END IF;
        ior_ilm_data(ln_cnt_work).rec_no := ln_cnt_work;
      END LOOP renumbering_loop;
    END IF;
--
  END blk_ilm_qry;
--
  /***********************************************************************************
   * Function Name    : get_parent_item_id
   * Description      : �e�i��ID�擾
   ***********************************************************************************/
  FUNCTION  get_parent_item_id(
              in_parent_item_id IN xxcmn_item_mst_v.item_id%TYPE)
              RETURN NUMBER
  IS
    -- �ϐ��錾
    on_parent_item_id   xxcmn_item_mst_b.parent_item_id%TYPE;
  BEGIN
--
    BEGIN
      SELECT ximv.parent_item_id
      INTO   on_parent_item_id
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_parent_item_id;
    END;
--
    -- �擾�����e�i��ID�����^�[��
    RETURN on_parent_item_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_parent_item_id;
--
--
  /***********************************************************************************
   * Function Name    : get_attribute5
   * Description      : ��\�q�Ɏ擾
   ***********************************************************************************/
  FUNCTION  get_attribute5(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN VARCHAR2
  IS
    -- �ϐ��錾
    lv_frequent_whse   xxcmn_item_locations_v.frequent_whse%TYPE;
    lv_segment1        xxcmn_item_locations_v.segment1%TYPE;
  BEGIN
--
    BEGIN
      SELECT xilv.frequent_whse,    -- ��\�q��
             xilv.segment1          -- �ۊǑq��
      INTO   lv_frequent_whse,
             lv_segment1
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.inventory_location_id = in_inventory_location_id;
    END;
--
    -- ��\�q�Ɂ��ۊǑq�ɂ̏ꍇ�A�擾������\�q�ɂ����^�[��
    IF (NVL(lv_frequent_whse, cv_dummy) = lv_segment1) THEN
      RETURN lv_frequent_whse;
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_attribute5;
--
--
  /***********************************************************************************
   * Function Name    : get_organization_id
   * Description      : �݌ɑg�DID�擾
   ***********************************************************************************/
  FUNCTION  get_organization_id(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN NUMBER
  IS
    -- �ϐ��錾
    on_organization_id  mtl_item_locations.organization_id%TYPE;
  BEGIN
--
    BEGIN
      SELECT xilv.mtl_organization_id
      INTO   on_organization_id
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.inventory_location_id = in_inventory_location_id;
    END;
--
    -- �擾�����݌ɑg�DID�����^�[��
    RETURN on_organization_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_organization_id;
--
--
  /***********************************************************************************
   * Function Name    : get_inv_stock_vol
   * Description      : �莝�݌ɐ��擾
   ***********************************************************************************/
  FUNCTION  get_inv_stock_vol(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    ln_temp_inv_stock_vol           NUMBER;
    ln_lot_id                       ic_lots_mst.lot_id%TYPE;
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- ���b�g�Ǘ��敪�擾
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �莝�݌ɐ��ʎZ�oAPI����.���b�gID�̐ݒ�
    IF (lv_lot_ctl = cv_lot_code1) THEN
      -- ���b�g�Ǘ��i�̏ꍇ�A���o�������b�gID��ݒ�
      ln_lot_id := in_lot_id;
    ELSE
      -- �񃍃b�g�Ǘ��i�̏ꍇ�ANULL��ݒ�
      ln_lot_id := NULL;
    END IF;
--
    -- ���ʊ֐���莝�݌ɐ��ʎZ�oAPI��R�[��
    ln_temp_inv_stock_vol := xxcmn_common2_pkg.get_stock_qty(
                               in_whse_id => in_inventory_location_id,  -- OPM�ۊǑq��ID
                               in_item_id => in_item_id,                -- OPM�i��ID
                               in_lot_id  => ln_lot_id);                -- ���b�gID
--
    RETURN ln_temp_inv_stock_vol;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_inv_stock_vol;
--
--
  /***********************************************************************************
   * Function Name    : get_supply_stock_plan
   * Description      : ���ɗ\�萔�擾
   ***********************************************************************************/
  FUNCTION  get_supply_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_hacchu_ukeire_yotei          NUMBER;    -- ���ɗ\�萔(7-2:��������\��)
    ln_idou_nyuuko_yotei_shiji      NUMBER;    -- ���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
    ln_idou_nyuuko_yotei_shukko     NUMBER;    -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
    ln_seisan_yotei                 NUMBER;    -- ���ɗ\�萔(7-5:���Y�\��)
    ln_temp_supply_stock_plan       NUMBER;    -- ���ɗ\�萔�ޔ�
    ld_max_date                     DATE;      -- �ő���t�i�[�ϐ�
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- �ϐ�������
    ln_hacchu_ukeire_yotei      := 0;
    ln_idou_nyuuko_yotei_shiji  := 0;
    ln_idou_nyuuko_yotei_shukko := 0;
    ln_seisan_yotei             := 0;
--
    -- �L�����t��NULL�ł���΁A���t�͈͂Ȃ��ɐ��ʂ��擾����
    IF (id_effective_date IS NULL) THEN
      ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), cv_date_format);
    ELSIF (id_effective_date IS NOT NULL) THEN
      ld_max_date := id_effective_date;
    END IF;
--
    -- ���b�g�Ǘ��敪�擾
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = cv_lot_code1) THEN
      -- �����b�g�i��
      -- ���ɗ\�萔(7-2:��������\��)
      xxcmn_common2_pkg.get_sup_lot_order_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        iv_item_code => iv_item_no,              -- �i�ڃR�[�h
        iv_lot_no    => iv_lot_no,               -- ���b�gNO
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_hacchu_ukeire_yotei,  -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
      xxcmn_common2_pkg.get_sup_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
      xxcmn_common2_pkg.get_sup_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-5:���Y�\��)
      xxcmn_common2_pkg.get_sup_lot_produce_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        in_item_id   => in_item_id,              -- �i��ID
        in_lot_id    => in_lot_id,               -- ���b�gID
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_seisan_yotei,         -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- �����b�g�iEND��
    ELSIF (lv_lot_ctl = cv_lot_code0) THEN
--
      -- ���񃍃b�g�i��
      -- ���ɗ\�萔(7-2:��������\��)
      xxcmn_common2_pkg.get_sup_order_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        iv_item_code => iv_item_no,              -- �i�ڃR�[�h
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_hacchu_ukeire_yotei,  -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      --���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
      xxcmn_common2_pkg.get_sup_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
      xxcmn_common2_pkg.get_sup_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ���񃍃b�g�iEND��
    END IF;
--
    -- �e���ʊ֐��ɂĎ擾�����l���T�}�� = ���ɗ\�萔
    ln_temp_supply_stock_plan := ln_hacchu_ukeire_yotei
                               + ln_idou_nyuuko_yotei_shiji
                               + ln_idou_nyuuko_yotei_shukko
                               + ln_seisan_yotei;
--
    RETURN ln_temp_supply_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_supply_stock_plan;
--
--
  /***********************************************************************************
   * Function Name    : get_take_stock_plan
   * Description      : �o�ɗ\�萔�擾
   ***********************************************************************************/
  FUNCTION  get_take_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_idou_shukko_yotei_shiji      NUMBER;    -- �o�ɗ\�萔(7-6:�ړ��o�ɗ\�� �w��)
    ln_idou_shukko_yotei_nyuuko     NUMBER;    -- �o�ɗ\�萔(7-7:�ړ��o�ɗ\�� ���ɕ񍐗L)
    ln_shukka_yotei                 NUMBER;    -- �o�ɗ\�萔(7-8:�o�ח\��)
    ln_yuushou_shukka_yotei         NUMBER;    -- �o�ɗ\�萔(7-9:�L���o�ח\��)
    ln_seisan_gen_tounyuu_yotei     NUMBER;    -- �o�ɗ\�萔(7-10:���Y���������\��)
    ln_aitesaki_zaiko               NUMBER;    -- �o�ɗ\�萔(7-11:�����݌�)
    ln_temp_take_stock_plan         NUMBER;    -- �o�ɗ\�萔�ޔ�
    ld_max_date                     DATE;      -- �ő���t�i�[�ϐ�
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- �ϐ�������
    ln_idou_shukko_yotei_shiji  := 0;
    ln_idou_shukko_yotei_nyuuko := 0;
    ln_shukka_yotei             := 0;
    ln_yuushou_shukka_yotei     := 0;
    ln_seisan_gen_tounyuu_yotei := 0;
    ln_aitesaki_zaiko           := 0;
--
    -- �L�����t��NULL�ł���΁A���t�͈͂Ȃ��ɐ��ʂ��擾����
    IF (id_effective_date IS NULL) THEN
      ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), cv_date_format);
    ELSIF (id_effective_date IS NOT NULL) THEN
      ld_max_date := id_effective_date;
    END IF;
--
    -- ���b�g�Ǘ��敪�擾
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = cv_lot_code1) THEN
--
      -- �����b�g�i��
      -- �o�ɗ\�萔(7-6:�ړ��o�ɗ\�� �w��)
      xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_shukko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-7:�ړ��o�ɗ\�� ���ɕ񍐗L)
      xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_shukko_yotei_nyuuko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-8:�o�ח\��)
      xxcmn_common2_pkg.get_dem_lot_ship_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_shukka_yotei,                -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-9:�L���o�ח\��)
      xxcmn_common2_pkg.get_dem_lot_provide_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_yuushou_shukka_yotei,        -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-10:���Y���������\��)
      xxcmn_common2_pkg.get_dem_lot_produce_qty(
        iv_whse_code => iv_segment1,                   -- �ۊǑq��ID
        in_item_id   => in_item_id,                    -- �i��ID
        in_lot_id    => in_lot_id,                     -- ���b�gID
        id_eff_date  => ld_max_date,                   -- �L�����t
        on_qty       => ln_seisan_gen_tounyuu_yotei,   -- ����
        ov_errbuf    => lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-11:�����݌�)
      xxcmn_common2_pkg.get_dem_lot_order_qty(
        iv_whse_code => iv_segment1,                   -- �ۊǑq�ɃR�[�h
        iv_item_code => iv_item_no,                    -- �i�ڃR�[�h
        in_lot_id    => in_lot_id,                     -- ���b�gID
        id_eff_date  => ld_max_date,                   -- �L�����t
        on_qty       => ln_aitesaki_zaiko,             -- ����
        ov_errbuf    => lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
          RETURN NULL;
      END IF;
      -- �����b�g�iEND��
    ELSIF (lv_lot_ctl = cv_lot_code0) THEN
--
      -- ���񃍃b�g�i��
      -- �o�ɗ\�萔(7-6:�ړ��o�ɗ\�� �w��)
      xxcmn_common2_pkg.get_dem_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_shukko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-7:�ړ��o�ɗ\�� ���ɕ񍐗L)
      xxcmn_common2_pkg.get_dem_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_shukko_yotei_nyuuko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-8:�o�ח\��)
      xxcmn_common2_pkg.get_dem_ship_qty(
        in_whse_id   => in_inventory_location_id,      -- �ۊǑq��ID
        iv_item_code => iv_item_no,                    -- �i�ڃR�[�h
        id_eff_date  => ld_max_date,                   -- �L�����t
        on_qty       => ln_shukka_yotei,               -- ����
        ov_errbuf    => lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-9:�L���o�ח\��)
      xxcmn_common2_pkg.get_dem_provide_qty(
        in_whse_id   => in_inventory_location_id,      -- �ۊǑq��ID
        iv_item_code => iv_item_no,                    -- �i�ڃR�[�h
        id_eff_date  => ld_max_date,                   -- �L�����t
        on_qty       => ln_yuushou_shukka_yotei,       -- ����
        ov_errbuf    => lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- �o�ɗ\�萔(7-10:���Y���������\��)
      xxcmn_common2_pkg.get_dem_produce_qty(
        iv_whse_code => iv_segment1,                   -- �ۊǑq�ɃR�[�h
        in_item_id   => in_item_id,                    -- �i��ID
        id_eff_date  => ld_max_date,                   -- �L�����t
        on_qty       => ln_seisan_gen_tounyuu_yotei,   -- ����
        ov_errbuf    => lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ���񃍃b�g�iEND��
    END IF;
--
    -- ���ʊ֐��ɂĎ擾�����l���T�}�� = �o�ɗ\�萔
    ln_temp_take_stock_plan := ln_idou_shukko_yotei_shiji
                             + ln_idou_shukko_yotei_nyuuko
                             + ln_shukka_yotei
                             + ln_yuushou_shukka_yotei
                             + ln_seisan_gen_tounyuu_yotei
                             + ln_aitesaki_zaiko;
--
    RETURN ln_temp_take_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_take_stock_plan;
--
--
  /***********************************************************************************
   * Function Name    : get_subtractable
   * Description      : �����\���擾
   ***********************************************************************************/
  FUNCTION  get_subtractable(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_temp_inv_stock_vol           NUMBER;    -- �莝�݌ɐ�
    ln_temp_supply_stock_plan       NUMBER;    -- ���ɗ\�萔
    ln_temp_take_stock_plan         NUMBER;    -- �o�ɗ\�萔
    ln_temp_subtractable            NUMBER;    -- �����\���ޔ�
  BEGIN
--
    -- �ϐ�������
    ln_temp_inv_stock_vol     := 0;
    ln_temp_supply_stock_plan := 0;
    ln_temp_take_stock_plan   := 0;
--
    -- �莝�݌ɐ��擾
    ln_temp_inv_stock_vol := get_inv_stock_vol(
                               in_inventory_location_id,
                               iv_item_no,
                               in_item_id,
                               in_lot_id,
                               in_loct_onhand);
--
    -- ���ɗ\�萔�擾
    ln_temp_supply_stock_plan := get_supply_stock_plan(
                                   iv_segment1,
                                   in_inventory_location_id,
                                   iv_item_no,
                                   in_item_id,
                                   iv_lot_no,
                                   in_lot_id,
                                   id_effective_date,
                                   in_loct_onhand);
--
    -- �o�ɗ\�萔�擾
    ln_temp_take_stock_plan := get_take_stock_plan(
                                 iv_segment1,
                                 in_inventory_location_id,
                                 iv_item_no,
                                 in_item_id,
                                 in_lot_id,
                                 id_effective_date,
                                 in_loct_onhand);
--
    -- �����\���Z�o(�����\�� = �莝�݌ɐ��擾 + ���ɗ\�萔�擾 - �o�ɗ\�萔�擾)
    ln_temp_subtractable := ln_temp_inv_stock_vol
                          + ln_temp_supply_stock_plan
                          - ln_temp_take_stock_plan;
--
    RETURN ln_temp_subtractable;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_subtractable;
--
END xxinv540001;
/
