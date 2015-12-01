CREATE OR REPLACE PACKAGE BODY APPS.XXCCP011A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP011A01C(body)
 * Description      : �i�ڊ֘A�}�X�^�ŐV��
 * MD.050           : �i�ڊ֘A�}�X�^�ŐV��
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_diff_record        �������R�[�h�擾(A-2)
 *  chk_exists_lkp         LOOKUP�\�L���`�F�b�N
 *  proc_mcb               �i�ڃJ�e�S���o�^�E�X�V(A-3)
 *  proc_iimb              OPM�i�ڃ}�X�^�o�^�E�X�V(A-4)
 *  proc_ximb              OPM�i�ڃA�h�I���o�^�E�X�V(A-5)
 *  proc_ccd               OPM�i�ڌ����o�^�E�X�V(A-6)
 *  proc_gic               OPM�i�ڃJ�e�S�������o�^�E�X�V(A-7)
 *  proc_msib              DISC�i�ڃ}�X�^�o�^�E�X�V(A-8)
 *  proc_xsib              DISC�i�ڃA�h�I���o�^�E�X�V(A-9)
 *  proc_xsibh             DISC�i�ڕύX�����A�h�I���o�^�E�X�V(A-10)
 *  proc_cicd              DISC�i�ڌ����o�^�E�X�V(A-13)
 *  proc_mic               DISC�i�ڃJ�e�S�������o�^�E�X�V(A-11)
 *  proc_mucc              �P�ʊ��Z�}�X�^�o�^�E�X�V(A-12)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/10/26    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(12)  := 'XXCCP011A01C';         -- �p�b�P�[�W��
--
  --�A�v���P�[�V�����Z�k��
  gv_appl_xxccp          CONSTANT VARCHAR2(5)   := 'XXCCP';                -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_bks_id              gl_sets_of_books.set_of_books_id%TYPE;        -- ��v����ID�i�[�p
  gt_calendar_code       cm_cmpt_dtl.calendar_code%TYPE;               -- ����v�N�x�i�[�p
  gt_org_code            mtl_parameters.organization_code%TYPE;        -- �g�D�R�[�h�i�[�p
  gt_org_id_hon          mtl_parameters.organization_id%TYPE;          -- �c�Ƒg�DID(�{�Ԋ�)�i�[�p
  gt_mst_org_id_hon      mtl_parameters.master_organization_id%TYPE;   -- �}�X�^�g�DID(�{�Ԋ�)�i�[�p
  gt_org_id_t4           mtl_parameters.organization_id%TYPE;          -- �c�Ƒg�DID(�����)�i�[�p
  gt_mst_org_id_t4       mtl_parameters.master_organization_id%TYPE;   -- �}�X�^�g�DID(�����)�i�[�p
  gd_process_date        DATE;                                         -- �Ɩ����t
  gv_chk_retcode         VARCHAR2(1);                                  -- LOOKUP�\�L���`�F�b�N�p
  -- �i�ڃJ�e�S��
  gn_mcb_i_cnt           NUMBER; -- �o�^����
  gn_mcb_u_cnt           NUMBER; -- �X�V����
  -- OPM�i�ڃ}�X�^
  gn_iimb_i_cnt          NUMBER; -- �o�^����
  gn_iimb_u_cnt          NUMBER; -- �X�V����
  -- OPM�i�ڃA�h�I��
  gn_ximb_i_cnt          NUMBER; -- �o�^����
  gn_ximb_u_cnt          NUMBER; -- �X�V����
  -- OPM�i�ڌ���
  gn_ccd_i_cnt           NUMBER; -- �o�^����
  gn_ccd_u_cnt           NUMBER; -- �X�V����
  -- OPM�i�ڃJ�e�S������
  gn_gic_i_cnt           NUMBER; -- �o�^����
  gn_gic_u_cnt           NUMBER; -- �X�V����
  -- DISC�i�ڃ}�X�^
  gn_msib_i_cnt          NUMBER; -- �o�^����
  gn_msib_u_cnt          NUMBER; -- �X�V����
  -- DISC�i�ڃA�h�I��
  gn_xsib_i_cnt          NUMBER; -- �o�^����
  gn_xsib_u_cnt          NUMBER; -- �X�V����
  -- DISC�i�ڕύX�����A�h�I��
  gn_xsibh_i_cnt         NUMBER; -- �o�^����
  gn_xsibh_u_cnt         NUMBER; -- �X�V����
  gn_xsibh_d_cnt         NUMBER; -- �폜����
  -- DISC�i�ڃJ�e�S������
  gn_mic_i_cnt           NUMBER; -- �o�^����
  gn_mic_u_cnt           NUMBER; -- �X�V����
  -- DISC�i�ڌ���
  gn_cicd_i_cnt          NUMBER; -- �o�^����
  gn_cicd_u_cnt          NUMBER; -- �X�V����
  -- �P�ʊ��Z�}�X�^
  gn_mucc_i_cnt          NUMBER; -- �o�^����
  gn_mucc_u_cnt          NUMBER; -- �X�V����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- OPM�i�ڃ}�X�^�������oSQL
  CURSOR get_iimb_cur
  IS
    --�ǉ�
    SELECT
      a.item_id                      AS item_id
     ,a.item_no                      AS item_no
     ,a.item_desc1                   AS item_desc1
     ,a.item_desc2                   AS item_desc2
     ,a.alt_itema                    AS alt_itema
     ,a.alt_itemb                    AS alt_itemb
     ,a.item_um                      AS item_um
     ,a.dualum_ind                   AS dualum_ind
     ,a.item_um2                     AS item_um2
     ,a.deviation_lo                 AS deviation_lo
     ,a.deviation_hi                 AS deviation_hi
     ,a.level_code                   AS level_code
     ,a.lot_ctl                      AS lot_ctl
     ,a.lot_indivisible              AS lot_indivisible
     ,a.sublot_ctl                   AS sublot_ctl
     ,a.loct_ctl                     AS loct_ctl
     ,a.noninv_ind                   AS noninv_ind
     ,a.match_type                   AS match_type
     ,a.inactive_ind                 AS inactive_ind
     ,a.inv_type                     AS inv_type
     ,a.shelf_life                   AS shelf_life
     ,a.retest_interval              AS retest_interval
     ,a.gl_class                     AS gl_class
     ,a.inv_class                    AS inv_class
     ,a.sales_class                  AS sales_class
     ,a.ship_class                   AS ship_class
     ,a.frt_class                    AS frt_class
     ,a.price_class                  AS price_class
     ,a.storage_class                AS storage_class
     ,a.purch_class                  AS purch_class
     ,a.tax_class                    AS tax_class
     ,a.customs_class                AS customs_class
     ,a.alloc_class                  AS alloc_class
     ,a.planning_class               AS planning_class
     ,a.itemcost_class               AS itemcost_class
     ,a.cost_mthd_code               AS cost_mthd_code
     ,a.upc_code                     AS upc_code
     ,a.grade_ctl                    AS grade_ctl
     ,a.status_ctl                   AS status_ctl
     ,a.qc_grade                     AS qc_grade
     ,a.lot_status                   AS lot_status
     ,a.bulk_id                      AS bulk_id
     ,a.pkg_id                       AS pkg_id
     ,a.qcitem_id                    AS qcitem_id
     ,a.qchold_res_code              AS qchold_res_code
     ,a.expaction_code               AS expaction_code
     ,a.fill_qty                     AS fill_qty
     ,a.fill_um                      AS fill_um
     ,a.expaction_interval           AS expaction_interval
     ,a.phantom_type                 AS phantom_type
     ,a.whse_item_id                 AS whse_item_id
     ,a2.item_no                     AS whse_item_no
     ,a.experimental_ind             AS experimental_ind
     ,a.exported_date                AS exported_date
     ,a.trans_cnt                    AS trans_cnt
     ,a.delete_mark                  AS delete_mark
     ,a.text_code                    AS text_code
     ,a.seq_dpnd_class               AS seq_dpnd_class
     ,a.commodity_code               AS commodity_code
     ,a.creation_date                AS creation_date
     ,a.created_by                   AS created_by
     ,a.last_update_date             AS last_update_date
     ,a.last_updated_by              AS last_updated_by
     ,a.last_update_login            AS last_update_login
     -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
     ,cn_program_application_id      AS program_application_id
     ,cn_program_id                  AS program_id
     ,cd_program_update_date         AS program_update_date
     --
     ,a.request_id                   AS request_id
     ,a.attribute1                   AS attribute1
     ,a.attribute2                   AS attribute2
     ,a.attribute3                   AS attribute3
     ,a.attribute4                   AS attribute4
     ,a.attribute5                   AS attribute5
     ,a.attribute6                   AS attribute6
     ,a.attribute7                   AS attribute7
     ,a.attribute8                   AS attribute8
     ,a.attribute9                   AS attribute9
     ,a.attribute10                  AS attribute10
     ,a.attribute11                  AS attribute11
     ,a.attribute12                  AS attribute12
     ,a.attribute13                  AS attribute13
     ,a.attribute14                  AS attribute14
     ,a.attribute15                  AS attribute15
     ,a.attribute16                  AS attribute16
     ,a.attribute17                  AS attribute17
     ,a.attribute18                  AS attribute18
     ,a.attribute19                  AS attribute19
     ,a.attribute20                  AS attribute20
     ,a.attribute21                  AS attribute21
     ,a.attribute22                  AS attribute22
     ,a.attribute23                  AS attribute23
     ,a.attribute24                  AS attribute24
     ,a.attribute25                  AS attribute25
     ,a.attribute26                  AS attribute26
     ,a.attribute27                  AS attribute27
     ,a.attribute28                  AS attribute28
     ,a.attribute29                  AS attribute29
     ,a.attribute30                  AS attribute30
     ,a.attribute_category           AS attribute_category
     ,a.item_abccode                 AS item_abccode
     ,a.ont_pricing_qty_source       AS ont_pricing_qty_source
     ,a.alloc_category_id            AS alloc_category_id
     ,a.customs_category_id          AS customs_category_id
     ,a.frt_category_id              AS frt_category_id
     ,a.gl_category_id               AS gl_category_id
     ,a.inv_category_id              AS inv_category_id
     ,a.cost_category_id             AS cost_category_id
     ,a.planning_category_id         AS planning_category_id
     ,a.price_category_id            AS price_category_id
     ,a.purch_category_id            AS purch_category_id
     ,a.sales_category_id            AS sales_category_id
     ,a.seq_category_id              AS seq_category_id
     ,a.ship_category_id             AS ship_category_id
     ,a.storage_category_id          AS storage_category_id
     ,a.tax_category_id              AS tax_category_id
     ,a.autolot_active_indicator     AS autolot_active_indicator
     ,a.lot_prefix                   AS lot_prefix
     ,a.lot_suffix                   AS lot_suffix
     ,a.sublot_prefix                AS sublot_prefix
     ,a.sublot_suffix                AS sublot_suffix
     ,'I'                            AS record_type
    FROM
      ic_item_mst_b@t4_hon  a
     ,ic_item_mst_b@t4_hon  a2
    WHERE a.whse_item_id = a2.item_id
      AND NOT EXISTS(
        SELECT 1
        FROM   ic_item_mst_b b
        WHERE  b.item_no = a.item_no
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      NULL                           AS item_id
     ,a.item_no                      AS item_no
     ,a.item_desc1                   AS item_desc1
     ,a.item_desc2                   AS item_desc2
     ,a.alt_itema                    AS alt_itema
     ,a.alt_itemb                    AS alt_itemb
     ,a.item_um                      AS item_um
     ,a.dualum_ind                   AS dualum_ind
     ,a.item_um2                     AS item_um2
     ,a.deviation_lo                 AS deviation_lo
     ,a.deviation_hi                 AS deviation_hi
     ,a.level_code                   AS level_code
     ,a.lot_ctl                      AS lot_ctl
     ,a.lot_indivisible              AS lot_indivisible
     ,a.sublot_ctl                   AS sublot_ctl
     ,a.loct_ctl                     AS loct_ctl
     ,a.noninv_ind                   AS noninv_ind
     ,a.match_type                   AS match_type
     ,a.inactive_ind                 AS inactive_ind
     ,a.inv_type                     AS inv_type
     ,a.shelf_life                   AS shelf_life
     ,a.retest_interval              AS retest_interval
     ,a.gl_class                     AS gl_class
     ,a.inv_class                    AS inv_class
     ,a.sales_class                  AS sales_class
     ,a.ship_class                   AS ship_class
     ,a.frt_class                    AS frt_class
     ,a.price_class                  AS price_class
     ,a.storage_class                AS storage_class
     ,a.purch_class                  AS purch_class
     ,a.tax_class                    AS tax_class
     ,a.customs_class                AS customs_class
     ,a.alloc_class                  AS alloc_class
     ,a.planning_class               AS planning_class
     ,a.itemcost_class               AS itemcost_class
     ,a.cost_mthd_code               AS cost_mthd_code
     ,a.upc_code                     AS upc_code
     ,a.grade_ctl                    AS grade_ctl
     ,a.status_ctl                   AS status_ctl
     ,a.qc_grade                     AS qc_grade
     ,a.lot_status                   AS lot_status
     ,a.bulk_id                      AS bulk_id
     ,a.pkg_id                       AS pkg_id
     ,a.qcitem_id                    AS qcitem_id
     ,a.qchold_res_code              AS qchold_res_code
     ,a.expaction_code               AS expaction_code
     ,a.fill_qty                     AS fill_qty
     ,a.fill_um                      AS fill_um
     ,a.expaction_interval           AS expaction_interval
     ,a.phantom_type                 AS phantom_type
     ,NULL                           AS whse_item_id
     ,a.item_no                      AS whse_item_no
     ,a.experimental_ind             AS experimental_ind
     ,a.exported_date                AS exported_date
     ,a.trans_cnt                    AS trans_cnt
     ,a.delete_mark                  AS delete_mark
     ,a.text_code                    AS text_code
     ,a.seq_dpnd_class               AS seq_dpnd_class
     ,a.commodity_code               AS commodity_code
     ,a.creation_date                AS creation_date
     ,a.created_by                   AS created_by
     ,a.last_update_date             AS last_update_date
     ,a.last_updated_by              AS last_updated_by
     ,a.last_update_login            AS last_update_login
     ,a.program_application_id       AS program_application_id
     ,a.program_id                   AS program_id
     ,a.program_update_date          AS program_update_date
     ,a.request_id                   AS request_id
     ,a.attribute1                   AS attribute1
     ,a.attribute2                   AS attribute2
     ,a.attribute3                   AS attribute3
     ,a.attribute4                   AS attribute4
     ,a.attribute5                   AS attribute5
     ,a.attribute6                   AS attribute6
     ,a.attribute7                   AS attribute7
     ,a.attribute8                   AS attribute8
     ,a.attribute9                   AS attribute9
     ,a.attribute10                  AS attribute10
     ,a.attribute11                  AS attribute11
     ,a.attribute12                  AS attribute12
     ,a.attribute13                  AS attribute13
     ,a.attribute14                  AS attribute14
     ,a.attribute15                  AS attribute15
     ,a.attribute16                  AS attribute16
     ,a.attribute17                  AS attribute17
     ,a.attribute18                  AS attribute18
     ,a.attribute19                  AS attribute19
     ,a.attribute20                  AS attribute20
     ,a.attribute21                  AS attribute21
     ,a.attribute22                  AS attribute22
     ,a.attribute23                  AS attribute23
     ,a.attribute24                  AS attribute24
     ,a.attribute25                  AS attribute25
     ,a.attribute26                  AS attribute26
     ,a.attribute27                  AS attribute27
     ,a.attribute28                  AS attribute28
     ,a.attribute29                  AS attribute29
     ,a.attribute30                  AS attribute30
     ,a.attribute_category           AS attribute_category
     ,a.item_abccode                 AS item_abccode
     ,a.ont_pricing_qty_source       AS ont_pricing_qty_source
     ,a.alloc_category_id            AS alloc_category_id
     ,a.customs_category_id          AS customs_category_id
     ,a.frt_category_id              AS frt_category_id
     ,a.gl_category_id               AS gl_category_id
     ,a.inv_category_id              AS inv_category_id
     ,a.cost_category_id             AS cost_category_id
     ,a.planning_category_id         AS planning_category_id
     ,a.price_category_id            AS price_category_id
     ,a.purch_category_id            AS purch_category_id
     ,a.sales_category_id            AS sales_category_id
     ,a.seq_category_id              AS seq_category_id
     ,a.ship_category_id             AS ship_category_id
     ,a.storage_category_id          AS storage_category_id
     ,a.tax_category_id              AS tax_category_id
     ,a.autolot_active_indicator     AS autolot_active_indicator
     ,a.lot_prefix                   AS lot_prefix
     ,a.lot_suffix                   AS lot_suffix
     ,a.sublot_prefix                AS sublot_prefix
     ,a.sublot_suffix                AS sublot_suffix
     ,'U'                            AS record_type
    FROM(
      SELECT
        NULL                              AS item_id
       ,iimb.item_no                      AS item_no
       ,iimb.item_desc1                   AS item_desc1
       ,iimb.item_desc2                   AS item_desc2
       ,iimb.alt_itema                    AS alt_itema
       ,iimb.alt_itemb                    AS alt_itemb
       ,iimb.item_um                      AS item_um
       ,iimb.dualum_ind                   AS dualum_ind
       ,iimb.item_um2                     AS item_um2
       ,iimb.deviation_lo                 AS deviation_lo
       ,iimb.deviation_hi                 AS deviation_hi
       ,iimb.level_code                   AS level_code
       ,iimb.lot_ctl                      AS lot_ctl
       ,iimb.lot_indivisible              AS lot_indivisible
       ,iimb.sublot_ctl                   AS sublot_ctl
       ,iimb.loct_ctl                     AS loct_ctl
       ,iimb.noninv_ind                   AS noninv_ind
       ,iimb.match_type                   AS match_type
       ,iimb.inactive_ind                 AS inactive_ind
       ,iimb.inv_type                     AS inv_type
       ,iimb.shelf_life                   AS shelf_life
       ,iimb.retest_interval              AS retest_interval
       ,iimb.gl_class                     AS gl_class
       ,iimb.inv_class                    AS inv_class
       ,iimb.sales_class                  AS sales_class
       ,iimb.ship_class                   AS ship_class
       ,iimb.frt_class                    AS frt_class
       ,iimb.price_class                  AS price_class
       ,iimb.storage_class                AS storage_class
       ,iimb.purch_class                  AS purch_class
       ,iimb.tax_class                    AS tax_class
       ,iimb.customs_class                AS customs_class
       ,iimb.alloc_class                  AS alloc_class
       ,iimb.planning_class               AS planning_class
       ,iimb.itemcost_class               AS itemcost_class
       ,iimb.cost_mthd_code               AS cost_mthd_code
       ,iimb.upc_code                     AS upc_code
       ,iimb.grade_ctl                    AS grade_ctl
       ,iimb.status_ctl                   AS status_ctl
       ,iimb.qc_grade                     AS qc_grade
       ,iimb.lot_status                   AS lot_status
       ,iimb.bulk_id                      AS bulk_id
       ,iimb.pkg_id                       AS pkg_id
       ,iimb.qcitem_id                    AS qcitem_id
       ,iimb.qchold_res_code              AS qchold_res_code
       ,iimb.expaction_code               AS expaction_code
       ,iimb.fill_qty                     AS fill_qty
       ,iimb.fill_um                      AS fill_um
       ,iimb.expaction_interval           AS expaction_interval
       ,iimb.phantom_type                 AS phantom_type
       ,NULL                              AS whse_item_id
       ,iimb2.item_no                     AS whse_item_no
       ,iimb.experimental_ind             AS experimental_ind
       ,iimb.exported_date                AS exported_date
       ,iimb.trans_cnt                    AS trans_cnt
       ,iimb.delete_mark                  AS delete_mark
       ,iimb.text_code                    AS text_code
       ,iimb.seq_dpnd_class               AS seq_dpnd_class
       ,iimb.commodity_code               AS commodity_code
       ,iimb.creation_date                AS creation_date
       ,iimb.created_by                   AS created_by
       ,iimb.last_update_date             AS last_update_date
       ,iimb.last_updated_by              AS last_updated_by
       ,iimb.last_update_login            AS last_update_login
       -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
       ,cn_program_application_id         AS program_application_id
       ,cn_program_id                     AS program_id
       ,cd_program_update_date            AS program_update_date
       --
       ,iimb.request_id                   AS request_id
       ,iimb.attribute1                   AS attribute1
       ,iimb.attribute2                   AS attribute2
       ,iimb.attribute3                   AS attribute3
       ,iimb.attribute4                   AS attribute4
       ,iimb.attribute5                   AS attribute5
       ,iimb.attribute6                   AS attribute6
       ,iimb.attribute7                   AS attribute7
       ,iimb.attribute8                   AS attribute8
       ,iimb.attribute9                   AS attribute9
       ,iimb.attribute10                  AS attribute10
       ,iimb.attribute11                  AS attribute11
       ,iimb.attribute12                  AS attribute12
       ,iimb.attribute13                  AS attribute13
       ,iimb.attribute14                  AS attribute14
       ,iimb.attribute15                  AS attribute15
       ,iimb.attribute16                  AS attribute16
       ,iimb.attribute17                  AS attribute17
       ,iimb.attribute18                  AS attribute18
       ,iimb.attribute19                  AS attribute19
       ,iimb.attribute20                  AS attribute20
       ,iimb.attribute21                  AS attribute21
       ,iimb.attribute22                  AS attribute22
       ,iimb.attribute23                  AS attribute23
       ,iimb.attribute24                  AS attribute24
       ,iimb.attribute25                  AS attribute25
       ,iimb.attribute26                  AS attribute26
       ,iimb.attribute27                  AS attribute27
       ,iimb.attribute28                  AS attribute28
       ,iimb.attribute29                  AS attribute29
       ,iimb.attribute30                  AS attribute30
       ,iimb.attribute_category           AS attribute_category
       ,iimb.item_abccode                 AS item_abccode
       ,iimb.ont_pricing_qty_source       AS ont_pricing_qty_source
       ,iimb.alloc_category_id            AS alloc_category_id
       ,iimb.customs_category_id          AS customs_category_id
       ,iimb.frt_category_id              AS frt_category_id
       ,iimb.gl_category_id               AS gl_category_id
       ,iimb.inv_category_id              AS inv_category_id
       ,iimb.cost_category_id             AS cost_category_id
       ,iimb.planning_category_id         AS planning_category_id
       ,iimb.price_category_id            AS price_category_id
       ,iimb.purch_category_id            AS purch_category_id
       ,iimb.sales_category_id            AS sales_category_id
       ,iimb.seq_category_id              AS seq_category_id
       ,iimb.ship_category_id             AS ship_category_id
       ,iimb.storage_category_id          AS storage_category_id
       ,iimb.tax_category_id              AS tax_category_id
       ,iimb.autolot_active_indicator     AS autolot_active_indicator
       ,iimb.lot_prefix                   AS lot_prefix
       ,iimb.lot_suffix                   AS lot_suffix
       ,iimb.sublot_prefix                AS sublot_prefix
       ,iimb.sublot_suffix                AS sublot_suffix
      FROM
        ic_item_mst_b@t4_hon  iimb
       ,ic_item_mst_b@t4_hon  iimb2
      WHERE
        iimb.whse_item_id = iimb2.item_id
      MINUS
        SELECT
          NULL                              AS item_id
         ,iimb.item_no                      AS item_no
         ,iimb.item_desc1                   AS item_desc1
         ,iimb.item_desc2                   AS item_desc2
         ,iimb.alt_itema                    AS alt_itema
         ,iimb.alt_itemb                    AS alt_itemb
         ,iimb.item_um                      AS item_um
         ,iimb.dualum_ind                   AS dualum_ind
         ,iimb.item_um2                     AS item_um2
         ,iimb.deviation_lo                 AS deviation_lo
         ,iimb.deviation_hi                 AS deviation_hi
         ,iimb.level_code                   AS level_code
         ,iimb.lot_ctl                      AS lot_ctl
         ,iimb.lot_indivisible              AS lot_indivisible
         ,iimb.sublot_ctl                   AS sublot_ctl
         ,iimb.loct_ctl                     AS loct_ctl
         ,iimb.noninv_ind                   AS noninv_ind
         ,iimb.match_type                   AS match_type
         ,iimb.inactive_ind                 AS inactive_ind
         ,iimb.inv_type                     AS inv_type
         ,iimb.shelf_life                   AS shelf_life
         ,iimb.retest_interval              AS retest_interval
         ,iimb.gl_class                     AS gl_class
         ,iimb.inv_class                    AS inv_class
         ,iimb.sales_class                  AS sales_class
         ,iimb.ship_class                   AS ship_class
         ,iimb.frt_class                    AS frt_class
         ,iimb.price_class                  AS price_class
         ,iimb.storage_class                AS storage_class
         ,iimb.purch_class                  AS purch_class
         ,iimb.tax_class                    AS tax_class
         ,iimb.customs_class                AS customs_class
         ,iimb.alloc_class                  AS alloc_class
         ,iimb.planning_class               AS planning_class
         ,iimb.itemcost_class               AS itemcost_class
         ,iimb.cost_mthd_code               AS cost_mthd_code
         ,iimb.upc_code                     AS upc_code
         ,iimb.grade_ctl                    AS grade_ctl
         ,iimb.status_ctl                   AS status_ctl
         ,iimb.qc_grade                     AS qc_grade
         ,iimb.lot_status                   AS lot_status
         ,iimb.bulk_id                      AS bulk_id
         ,iimb.pkg_id                       AS pkg_id
         ,iimb.qcitem_id                    AS qcitem_id
         ,iimb.qchold_res_code              AS qchold_res_code
         ,iimb.expaction_code               AS expaction_code
         ,iimb.fill_qty                     AS fill_qty
         ,iimb.fill_um                      AS fill_um
         ,iimb.expaction_interval           AS expaction_interval
         ,iimb.phantom_type                 AS phantom_type
         ,NULL                              AS whse_item_id
         ,iimb2.item_no                     AS whse_item_no
         ,iimb.experimental_ind             AS experimental_ind
         ,iimb.exported_date                AS exported_date
         ,iimb.trans_cnt                    AS trans_cnt
         ,iimb.delete_mark                  AS delete_mark
         ,iimb.text_code                    AS text_code
         ,iimb.seq_dpnd_class               AS seq_dpnd_class
         ,iimb.commodity_code               AS commodity_code
         ,iimb.creation_date                AS creation_date
         ,iimb.created_by                   AS created_by
         ,iimb.last_update_date             AS last_update_date
         ,iimb.last_updated_by              AS last_updated_by
         ,iimb.last_update_login            AS last_update_login
         -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
         ,cn_program_application_id         AS program_application_id
         ,cn_program_id                     AS program_id
         ,cd_program_update_date            AS program_update_date
         --
         ,iimb.request_id                   AS request_id
         ,iimb.attribute1                   AS attribute1
         ,iimb.attribute2                   AS attribute2
         ,iimb.attribute3                   AS attribute3
         ,iimb.attribute4                   AS attribute4
         ,iimb.attribute5                   AS attribute5
         ,iimb.attribute6                   AS attribute6
         ,iimb.attribute7                   AS attribute7
         ,iimb.attribute8                   AS attribute8
         ,iimb.attribute9                   AS attribute9
         ,iimb.attribute10                  AS attribute10
         ,iimb.attribute11                  AS attribute11
         ,iimb.attribute12                  AS attribute12
         ,iimb.attribute13                  AS attribute13
         ,iimb.attribute14                  AS attribute14
         ,iimb.attribute15                  AS attribute15
         ,iimb.attribute16                  AS attribute16
         ,iimb.attribute17                  AS attribute17
         ,iimb.attribute18                  AS attribute18
         ,iimb.attribute19                  AS attribute19
         ,iimb.attribute20                  AS attribute20
         ,iimb.attribute21                  AS attribute21
         ,iimb.attribute22                  AS attribute22
         ,iimb.attribute23                  AS attribute23
         ,iimb.attribute24                  AS attribute24
         ,iimb.attribute25                  AS attribute25
         ,iimb.attribute26                  AS attribute26
         ,iimb.attribute27                  AS attribute27
         ,iimb.attribute28                  AS attribute28
         ,iimb.attribute29                  AS attribute29
         ,iimb.attribute30                  AS attribute30
         ,iimb.attribute_category           AS attribute_category
         ,iimb.item_abccode                 AS item_abccode
         ,iimb.ont_pricing_qty_source       AS ont_pricing_qty_source
         ,iimb.alloc_category_id            AS alloc_category_id
         ,iimb.customs_category_id          AS customs_category_id
         ,iimb.frt_category_id              AS frt_category_id
         ,iimb.gl_category_id               AS gl_category_id
         ,iimb.inv_category_id              AS inv_category_id
         ,iimb.cost_category_id             AS cost_category_id
         ,iimb.planning_category_id         AS planning_category_id
         ,iimb.price_category_id            AS price_category_id
         ,iimb.purch_category_id            AS purch_category_id
         ,iimb.sales_category_id            AS sales_category_id
         ,iimb.seq_category_id              AS seq_category_id
         ,iimb.ship_category_id             AS ship_category_id
         ,iimb.storage_category_id          AS storage_category_id
         ,iimb.tax_category_id              AS tax_category_id
         ,iimb.autolot_active_indicator     AS autolot_active_indicator
         ,iimb.lot_prefix                   AS lot_prefix
         ,iimb.lot_suffix                   AS lot_suffix
         ,iimb.sublot_prefix                AS sublot_prefix
         ,iimb.sublot_suffix                AS sublot_suffix
        FROM
          ic_item_mst_b  iimb
         ,ic_item_mst_b  iimb2
        WHERE
          iimb.whse_item_id = iimb2.item_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   ic_item_mst_b  b
      WHERE  a.item_no = b.item_no
    )
  ;
  TYPE get_iimb_ttype IS TABLE OF xxccp_ic_item_mst_b%ROWTYPE INDEX BY BINARY_INTEGER;
  get_iimb_tab get_iimb_ttype;
--
 -- OPM�i�ڃA�h�I���������oSQL
  CURSOR get_ximb_cur
  IS
    --�ǉ�
    SELECT
      a.item_id                      AS item_id
     ,a2.item_no                     AS item_no
     ,a.start_date_active            AS start_date_active
     ,a.end_date_active              AS end_date_active
     ,a.active_flag                  AS active_flag
     ,a.item_name                    AS item_name
     ,a.item_short_name              AS item_short_name
     ,a.item_name_alt                AS item_name_alt
     ,a.parent_item_id               AS parent_item_id
     ,a3.item_no                     AS parent_item_no
     ,a.obsolete_class               AS obsolete_class
     ,a.obsolete_date                AS obsolete_date
     ,a.model_type                   AS model_type
     ,a.product_class                AS product_class
     ,a.product_type                 AS product_type
     ,a.expiration_day               AS expiration_day
     ,a.delivery_lead_time           AS delivery_lead_time
     ,a.whse_county_code             AS whse_county_code
     ,a.standard_yield               AS standard_yield
     ,a.shipping_end_date            AS shipping_end_date
     ,a.rate_class                   AS rate_class
     ,a.shelf_life                   AS shelf_life
     ,a.shelf_life_class             AS shelf_life_class
     ,a.bottle_class                 AS bottle_class
     ,a.uom_class                    AS uom_class
     ,a.inventory_chk_class          AS inventory_chk_class
     ,a.trace_class                  AS trace_class
     ,a.shipping_cs_unit_qty         AS shipping_cs_unit_qty
     ,a.palette_max_cs_qty           AS palette_max_cs_qty
     ,a.palette_max_step_qty         AS palette_max_step_qty
     ,a.palette_step_qty             AS palette_step_qty
     ,a.cs_weigth_or_capacity        AS cs_weigth_or_capacity
     ,a.raw_material_consumption     AS raw_material_consumption
     ,a.attribute1                   AS attribute1
     ,a.attribute2                   AS attribute2
     ,a.attribute3                   AS attribute3
     ,a.attribute4                   AS attribute4
     ,a.attribute5                   AS attribute5
     ,a.created_by                   AS created_by
     ,a.creation_date                AS creation_date
     ,a.last_updated_by              AS last_updated_by
     ,a.last_update_date             AS last_update_date
     ,a.last_update_login            AS last_update_login
     ,a.request_id                   AS request_id
     ,a.program_application_id       AS program_application_id
     ,a.program_id                   AS program_id
     ,a.program_update_date          AS program_update_date
     ,'I'                            AS record_type
    FROM
      xxcmn_item_mst_b@t4_hon  a
     ,ic_item_mst_b@t4_hon     a2
     ,ic_item_mst_b@t4_hon     a3
    WHERE a.item_id        = a2.item_id
      AND a.parent_item_id = a3.item_id
      AND NOT EXISTS(
        SELECT 1
        FROM   xxcmn_item_mst_b b
              ,ic_item_mst_b    b2
        WHERE  b.item_id           = b2.item_id
          AND  b2.item_no          = a2.item_no
          AND  b.start_date_active = a.start_date_active
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.item_id                      AS item_id
     ,a.item_no                      AS item_no
     ,a.start_date_active            AS start_date_active
     ,a.end_date_active              AS end_date_active
     ,a.active_flag                  AS active_flag
     ,a.item_name                    AS item_name
     ,a.item_short_name              AS item_short_name
     ,a.item_name_alt                AS item_name_alt
     ,a.parent_item_id               AS parent_item_id
     ,a.parent_item_no               AS parent_item_no
     ,a.obsolete_class               AS obsolete_class
     ,a.obsolete_date                AS obsolete_date
     ,a.model_type                   AS model_type
     ,a.product_class                AS product_class
     ,a.product_type                 AS product_type
     ,a.expiration_day               AS expiration_day
     ,a.delivery_lead_time           AS delivery_lead_time
     ,a.whse_county_code             AS whse_county_code
     ,a.standard_yield               AS standard_yield
     ,a.shipping_end_date            AS shipping_end_date
     ,a.rate_class                   AS rate_class
     ,a.shelf_life                   AS shelf_life
     ,a.shelf_life_class             AS shelf_life_class
     ,a.bottle_class                 AS bottle_class
     ,a.uom_class                    AS uom_class
     ,a.inventory_chk_class          AS inventory_chk_class
     ,a.trace_class                  AS trace_class
     ,a.shipping_cs_unit_qty         AS shipping_cs_unit_qty
     ,a.palette_max_cs_qty           AS palette_max_cs_qty
     ,a.palette_max_step_qty         AS palette_max_step_qty
     ,a.palette_step_qty             AS palette_step_qty
     ,a.cs_weigth_or_capacity        AS cs_weigth_or_capacity
     ,a.raw_material_consumption     AS raw_material_consumption
     ,a.attribute1                   AS attribute1
     ,a.attribute2                   AS attribute2
     ,a.attribute3                   AS attribute3
     ,a.attribute4                   AS attribute4
     ,a.attribute5                   AS attribute5
     ,a.created_by                   AS created_by
     ,a.creation_date                AS creation_date
     ,a.last_updated_by              AS last_updated_by
     ,a.last_update_date             AS last_update_date
     ,a.last_update_login            AS last_update_login
     ,a.request_id                   AS request_id
     ,a.program_application_id       AS program_application_id
     ,a.program_id                   AS program_id
     ,a.program_update_date          AS program_update_date
     ,'U'                            AS record_type
    FROM(
      SELECT
        NULL                           AS item_id
       ,iimb.item_no                   AS item_no
       ,ximb.start_date_active         AS start_date_active
       ,ximb.end_date_active           AS end_date_active
       ,ximb.active_flag               AS active_flag
       ,ximb.item_name                 AS item_name
       ,ximb.item_short_name           AS item_short_name
       ,ximb.item_name_alt             AS item_name_alt
       ,NULL                           AS parent_item_id
       ,iimb2.item_no                  AS parent_item_no
       ,ximb.obsolete_class            AS obsolete_class
       ,ximb.obsolete_date             AS obsolete_date
       ,ximb.model_type                AS model_type
       ,ximb.product_class             AS product_class
       ,ximb.product_type              AS product_type
       ,ximb.expiration_day            AS expiration_day
       ,ximb.delivery_lead_time        AS delivery_lead_time
       ,ximb.whse_county_code          AS whse_county_code
       ,ximb.standard_yield            AS standard_yield
       ,ximb.shipping_end_date         AS shipping_end_date
       ,ximb.rate_class                AS rate_class
       ,ximb.shelf_life                AS shelf_life
       ,ximb.shelf_life_class          AS shelf_life_class
       ,ximb.bottle_class              AS bottle_class
       ,ximb.uom_class                 AS uom_class
       ,ximb.inventory_chk_class       AS inventory_chk_class
       ,ximb.trace_class               AS trace_class
       ,ximb.shipping_cs_unit_qty      AS shipping_cs_unit_qty
       ,ximb.palette_max_cs_qty        AS palette_max_cs_qty
       ,ximb.palette_max_step_qty      AS palette_max_step_qty
       ,ximb.palette_step_qty          AS palette_step_qty
       ,ximb.cs_weigth_or_capacity     AS cs_weigth_or_capacity
       ,ximb.raw_material_consumption  AS raw_material_consumption
       ,ximb.attribute1                AS attribute1
       ,ximb.attribute2                AS attribute2
       ,ximb.attribute3                AS attribute3
       ,ximb.attribute4                AS attribute4
       ,ximb.attribute5                AS attribute5
       ,ximb.created_by                AS created_by
       ,ximb.creation_date             AS creation_date
       ,ximb.last_updated_by           AS last_updated_by
       ,ximb.last_update_date          AS last_update_date
       ,ximb.last_update_login         AS last_update_login
       ,ximb.request_id                AS request_id
       ,ximb.program_application_id    AS program_application_id
       ,ximb.program_id                AS program_id
       ,ximb.program_update_date       AS program_update_date
      FROM
        xxcmn_item_mst_b@t4_hon  ximb
       ,ic_item_mst_b@t4_hon     iimb
       ,ic_item_mst_b@t4_hon     iimb2
      WHERE
        iimb.item_id  = ximb.item_id
      AND
        iimb2.item_id = ximb.parent_item_id
      MINUS
        SELECT
          NULL                           AS item_id
         ,iimb.item_no                   AS item_no
         ,ximb.start_date_active         AS start_date_active
         ,ximb.end_date_active           AS end_date_active
         ,ximb.active_flag               AS active_flag
         ,ximb.item_name                 AS item_name
         ,ximb.item_short_name           AS item_short_name
         ,ximb.item_name_alt             AS item_name_alt
         ,NULL                           AS parent_item_id
         ,iimb2.item_no                  AS parent_item_no
         ,ximb.obsolete_class            AS obsolete_class
         ,ximb.obsolete_date             AS obsolete_date
         ,ximb.model_type                AS model_type
         ,ximb.product_class             AS product_class
         ,ximb.product_type              AS product_type
         ,ximb.expiration_day            AS expiration_day
         ,ximb.delivery_lead_time        AS delivery_lead_time
         ,ximb.whse_county_code          AS whse_county_code
         ,ximb.standard_yield            AS standard_yield
         ,ximb.shipping_end_date         AS shipping_end_date
         ,ximb.rate_class                AS rate_class
         ,ximb.shelf_life                AS shelf_life
         ,ximb.shelf_life_class          AS shelf_life_class
         ,ximb.bottle_class              AS bottle_class
         ,ximb.uom_class                 AS uom_class
         ,ximb.inventory_chk_class       AS inventory_chk_class
         ,ximb.trace_class               AS trace_class
         ,ximb.shipping_cs_unit_qty      AS shipping_cs_unit_qty
         ,ximb.palette_max_cs_qty        AS palette_max_cs_qty
         ,ximb.palette_max_step_qty      AS palette_max_step_qty
         ,ximb.palette_step_qty          AS palette_step_qty
         ,ximb.cs_weigth_or_capacity     AS cs_weigth_or_capacity
         ,ximb.raw_material_consumption  AS raw_material_consumption
         ,ximb.attribute1                AS attribute1
         ,ximb.attribute2                AS attribute2
         ,ximb.attribute3                AS attribute3
         ,ximb.attribute4                AS attribute4
         ,ximb.attribute5                AS attribute5
         ,ximb.created_by                AS created_by
         ,ximb.creation_date             AS creation_date
         ,ximb.last_updated_by           AS last_updated_by
         ,ximb.last_update_date          AS last_update_date
         ,ximb.last_update_login         AS last_update_login
         ,ximb.request_id                AS request_id
         ,ximb.program_application_id    AS program_application_id
         ,ximb.program_id                AS program_id
         ,ximb.program_update_date       AS program_update_date
        FROM
          xxcmn_item_mst_b  ximb
         ,ic_item_mst_b     iimb
         ,ic_item_mst_b     iimb2
        WHERE
          iimb.item_id = ximb.item_id
        AND
          iimb2.item_id = ximb.parent_item_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   xxcmn_item_mst_b b
            ,ic_item_mst_b    b2
      WHERE  b.item_id           = b2.item_id
        AND  b2.item_no          = a.item_no
        AND  b.start_date_active = a.start_date_active
    )
  ;
  TYPE get_ximb_ttype IS TABLE OF xxccp_xcmn_item_mst_b%ROWTYPE INDEX BY BINARY_INTEGER;
  get_ximb_tab get_ximb_ttype;
--
  -- OPM�i�ڃJ�e�S�������������oSQL
  CURSOR get_gic_cur
  IS
    --�ǉ�
    SELECT
      gic.item_id            AS item_id
     ,iimb.item_no           AS item_no
     ,gic.category_set_id    AS category_set_id
     ,mcsv.category_set_name AS category_set_name
     ,gic.category_id        AS category_id
     ,mcv.segment1           AS segment1
     ,cn_created_by          AS created_by
     ,cd_creation_date       AS creation_date
     ,cn_last_updated_by     AS last_updated_by
     ,cd_last_update_date    AS last_update_date
     ,cn_last_update_login   AS last_update_login
     ,'I'                    AS record_type
    FROM
      gmi_item_categories@t4_hon  gic
     ,mtl_category_sets_vl@t4_hon mcsv
     ,mtl_categories_vl@t4_hon    mcv
     ,ic_item_mst_b@t4_hon        iimb
    WHERE gic.category_set_id = mcsv.category_set_id
      AND gic.category_id     = mcv.category_id
      AND gic.item_id         = iimb.item_id
      AND NOT EXISTS(
        SELECT 1
        FROM   gmi_item_categories  gic2
              ,mtl_category_sets_vl mcsv2
              ,mtl_categories_vl    mcv2
              ,ic_item_mst_b        iimb2
        WHERE gic2.category_set_id   = mcsv2.category_set_id
          AND gic2.category_id       = mcv2.category_id
          AND gic2.item_id           = iimb2.item_id
          AND mcsv.category_set_name = mcsv2.category_set_name
          AND iimb.item_no           = iimb2.item_no
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.item_id           AS item_id
     ,a.item_no           AS item_no
     ,a.category_set_id   AS category_set_id
     ,a.category_set_name AS category_set_name
     ,a.category_id       AS category_id
     ,a.segment1          AS segment1
     ,a.created_by        AS created_by
     ,a.creation_date     AS creation_date
     ,a.last_updated_by   AS last_updated_by
     ,a.last_update_date  AS last_update_date
     ,a.last_update_login AS last_update_login
     ,'U'                 AS record_type
    FROM(
      SELECT
        NULL                   AS item_id
       ,iimb.item_no           AS item_no
       ,NULL                   AS category_set_id
       ,mcsv.category_set_name AS category_set_name
       ,NULL                   AS category_id
       ,mcv.segment1           AS segment1
       ,cn_created_by          AS created_by
       ,cd_creation_date       AS creation_date
       ,cn_last_updated_by     AS last_updated_by
       ,cd_last_update_date    AS last_update_date
       ,cn_last_update_login   AS last_update_login
      FROM
        gmi_item_categories@t4_hon  gic
       ,mtl_category_sets_vl@t4_hon mcsv
       ,mtl_categories_vl@t4_hon    mcv
       ,ic_item_mst_b@t4_hon        iimb
      WHERE gic.category_set_id = mcsv.category_set_id
        AND gic.category_id     = mcv.category_id
        AND gic.item_id         = iimb.item_id
      MINUS
        SELECT
          NULL                   AS item_id
         ,iimb.item_no           AS item_no
         ,NULL                   AS category_set_id
         ,mcsv.category_set_name AS category_set_name
         ,NULL                   AS category_id
         ,mcv.segment1           AS segment1
         ,cn_created_by          AS created_by
         ,cd_creation_date       AS creation_date
         ,cn_last_updated_by     AS last_updated_by
         ,cd_last_update_date    AS last_update_date
         ,cn_last_update_login   AS last_update_login
        FROM
          gmi_item_categories  gic
         ,mtl_category_sets_vl mcsv
         ,mtl_categories_vl    mcv
         ,ic_item_mst_b        iimb
        WHERE gic.category_set_id = mcsv.category_set_id
          AND gic.category_id     = mcv.category_id
          AND gic.item_id         = iimb.item_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   gmi_item_categories  gic3
            ,mtl_category_sets_vl mcsv3
            ,mtl_categories_vl    mcv3
            ,ic_item_mst_b        iimb3
      WHERE gic3.category_set_id   = mcsv3.category_set_id
        AND gic3.category_id       = mcv3.category_id
        AND gic3.item_id           = iimb3.item_id
        AND a.category_set_name    = mcsv3.category_set_name
        AND a.item_no              = iimb3.item_no
    )
  ;
  TYPE get_gic_ttype IS TABLE OF xxccp_gmi_item_categories%ROWTYPE INDEX BY BINARY_INTEGER;
  get_gic_tab get_gic_ttype;
--
  -- OPM�i�ڌ����������oSQL
  CURSOR get_ccd_cur
  IS
    --�ǉ�
    SELECT
      a.cmpntcost_id            AS cmpntcost_id
     ,a.item_id                 AS item_id
     ,a2.item_no                AS item_no
     ,a.whse_code               AS whse_code
     ,a.calendar_code           AS calendar_code
     ,a.period_code             AS period_code
     ,a.cost_mthd_code          AS cost_mthd_code
     ,a.cost_cmpntcls_id        AS cost_cmpntcls_id
     ,a.cost_analysis_code      AS cost_analysis_code
     ,a.cost_level              AS cost_level
     ,a.cmpnt_cost              AS cmpnt_cost
     ,a.burden_ind              AS burden_ind
     ,a.fmeff_id                AS fmeff_id
     ,a.rollover_ind            AS rollover_ind
     ,a.total_qty               AS total_qty
     ,a.costcalc_orig           AS costcalc_orig
     ,a.rmcalc_type             AS rmcalc_type
     ,a.rollup_ref_no           AS rollup_ref_no
     ,a.acproc_id               AS acproc_id
     ,a.trans_cnt               AS trans_cnt
     ,a.text_code               AS text_code
     ,a.delete_mark             AS delete_mark
     ,cn_request_id             AS request_id
     ,cn_program_application_id AS program_application_id
     ,cn_program_id             AS program_id
     ,cd_program_update_date    AS program_update_date
     ,a.attribute1              AS attribute1
     ,a.attribute2              AS attribute2
     ,a.attribute3              AS attribute3
     ,a.attribute4              AS attribute4
     ,a.attribute5              AS attribute5
     ,a.attribute6              AS attribute6
     ,a.attribute7              AS attribute7
     ,a.attribute8              AS attribute8
     ,a.attribute9              AS attribute9
     ,a.attribute10             AS attribute10
     ,a.attribute11             AS attribute11
     ,a.attribute12             AS attribute12
     ,a.attribute13             AS attribute13
     ,a.attribute14             AS attribute14
     ,a.attribute15             AS attribute15
     ,a.attribute16             AS attribute16
     ,a.attribute17             AS attribute17
     ,a.attribute18             AS attribute18
     ,a.attribute19             AS attribute19
     ,a.attribute20             AS attribute20
     ,a.attribute21             AS attribute21
     ,a.attribute22             AS attribute22
     ,a.attribute23             AS attribute23
     ,a.attribute24             AS attribute24
     ,a.attribute25             AS attribute25
     ,a.attribute26             AS attribute26
     ,a.attribute27             AS attribute27
     ,a.attribute28             AS attribute28
     ,a.attribute29             AS attribute29
     ,a.attribute30             AS attribute30
     ,cn_created_by             AS created_by
     ,cd_creation_date          AS creation_date
     ,cn_last_updated_by        AS last_updated_by
     ,cd_last_update_date       AS last_update_date
     ,cn_last_update_login      AS last_update_login
     ,a.attribute_category      AS attribute_category
     ,a.period_trans_qty        AS period_trans_qty
     ,a.period_perp_qty         AS period_perp_qty
     ,'I'                       AS record_type
    FROM
      cm_cmpt_dtl@t4_hon    a
     ,ic_item_mst_b@t4_hon  a2
    WHERE a.item_id       = a2.item_id
      AND a.calendar_code = gt_calendar_code -- ����v�N�x
      AND NOT EXISTS(
        SELECT 1
        FROM   cm_cmpt_dtl    b
             , ic_item_mst_b  b2
        WHERE  b.item_id          = b2.item_id
          AND  b2.item_no         = a2.item_no
          AND  b.calendar_code    = a.calendar_code
          AND  b.cost_cmpntcls_id = a.cost_cmpntcls_id
    )
--
    UNION ALL
--
    --�X�V
    SELECT
       a.cmpntcost_id           AS cmpntcost_id
      ,a.item_id                AS item_id
      ,a.item_no                AS item_no
      ,a.whse_code              AS whse_code
      ,a.calendar_code          AS calendar_code
      ,a.period_code            AS period_code
      ,a.cost_mthd_code         AS cost_mthd_code
      ,a.cost_cmpntcls_id       AS cost_cmpntcls_id
      ,a.cost_analysis_code     AS cost_analysis_code
      ,a.cost_level             AS cost_level
      ,a.cmpnt_cost             AS cmpnt_cost
      ,a.burden_ind             AS burden_ind
      ,a.fmeff_id               AS fmeff_id
      ,a.rollover_ind           AS rollover_ind
      ,a.total_qty              AS total_qty
      ,a.costcalc_orig          AS costcalc_orig
      ,a.rmcalc_type            AS rmcalc_type
      ,a.rollup_ref_no          AS rollup_ref_no
      ,a.acproc_id              AS acproc_id
      ,a.trans_cnt              AS trans_cnt
      ,a.text_code              AS text_code
      ,a.delete_mark            AS delete_mark
      ,a.request_id             AS request_id
      ,a.program_application_id AS program_application_id
      ,a.program_id             AS program_id
      ,a.program_update_date    AS program_update_date
      ,a.attribute1             AS attribute1
      ,a.attribute2             AS attribute2
      ,a.attribute3             AS attribute3
      ,a.attribute4             AS attribute4
      ,a.attribute5             AS attribute5
      ,a.attribute6             AS attribute6
      ,a.attribute7             AS attribute7
      ,a.attribute8             AS attribute8
      ,a.attribute9             AS attribute9
      ,a.attribute10            AS attribute10
      ,a.attribute11            AS attribute11
      ,a.attribute12            AS attribute12
      ,a.attribute13            AS attribute13
      ,a.attribute14            AS attribute14
      ,a.attribute15            AS attribute15
      ,a.attribute16            AS attribute16
      ,a.attribute17            AS attribute17
      ,a.attribute18            AS attribute18
      ,a.attribute19            AS attribute19
      ,a.attribute20            AS attribute20
      ,a.attribute21            AS attribute21
      ,a.attribute22            AS attribute22
      ,a.attribute23            AS attribute23
      ,a.attribute24            AS attribute24
      ,a.attribute25            AS attribute25
      ,a.attribute26            AS attribute26
      ,a.attribute27            AS attribute27
      ,a.attribute28            AS attribute28
      ,a.attribute29            AS attribute29
      ,a.attribute30            AS attribute30
      ,a.created_by             AS created_by
      ,a.creation_date          AS creation_date
      ,a.last_updated_by        AS last_updated_by
      ,a.last_update_date       AS last_update_date
      ,a.last_update_login      AS last_update_login
      ,a.attribute_category     AS attribute_category
      ,a.period_trans_qty       AS period_trans_qty
      ,a.period_perp_qty        AS period_perp_qty
      ,'U'
    FROM
        (SELECT
           NULL                       AS cmpntcost_id
          ,NULL                       AS item_id
          ,iimb.item_no               AS item_no
          ,ccd.whse_code              AS whse_code
          ,ccd.calendar_code          AS calendar_code
          ,ccd.period_code            AS period_code
          ,ccd.cost_mthd_code         AS cost_mthd_code
          ,ccd.cost_cmpntcls_id       AS cost_cmpntcls_id
          ,ccd.cost_analysis_code     AS cost_analysis_code
          ,ccd.cost_level             AS cost_level
          ,ccd.cmpnt_cost             AS cmpnt_cost
          ,ccd.burden_ind             AS burden_ind
          ,ccd.fmeff_id               AS fmeff_id
          ,ccd.rollover_ind           AS rollover_ind
          ,ccd.total_qty              AS total_qty
          ,ccd.costcalc_orig          AS costcalc_orig
          ,ccd.rmcalc_type            AS rmcalc_type
          ,ccd.rollup_ref_no          AS rollup_ref_no
          ,ccd.acproc_id              AS acproc_id
          ,ccd.trans_cnt              AS trans_cnt
          ,ccd.text_code              AS text_code
          ,ccd.delete_mark            AS delete_mark
          ,cn_request_id              AS request_id
          ,cn_program_application_id  AS program_application_id
          ,cn_program_id              AS program_id
          ,cd_program_update_date     AS program_update_date
          ,ccd.attribute1             AS attribute1
          ,ccd.attribute2             AS attribute2
          ,ccd.attribute3             AS attribute3
          ,ccd.attribute4             AS attribute4
          ,ccd.attribute5             AS attribute5
          ,ccd.attribute6             AS attribute6
          ,ccd.attribute7             AS attribute7
          ,ccd.attribute8             AS attribute8
          ,ccd.attribute9             AS attribute9
          ,ccd.attribute10            AS attribute10
          ,ccd.attribute11            AS attribute11
          ,ccd.attribute12            AS attribute12
          ,ccd.attribute13            AS attribute13
          ,ccd.attribute14            AS attribute14
          ,ccd.attribute15            AS attribute15
          ,ccd.attribute16            AS attribute16
          ,ccd.attribute17            AS attribute17
          ,ccd.attribute18            AS attribute18
          ,ccd.attribute19            AS attribute19
          ,ccd.attribute20            AS attribute20
          ,ccd.attribute21            AS attribute21
          ,ccd.attribute22            AS attribute22
          ,ccd.attribute23            AS attribute23
          ,ccd.attribute24            AS attribute24
          ,ccd.attribute25            AS attribute25
          ,ccd.attribute26            AS attribute26
          ,ccd.attribute27            AS attribute27
          ,ccd.attribute28            AS attribute28
          ,ccd.attribute29            AS attribute29
          ,ccd.attribute30            AS attribute30
          ,cn_created_by              AS created_by
          ,cd_creation_date           AS creation_date
          ,cn_last_updated_by         AS last_updated_by
          ,cd_last_update_date        AS last_update_date
          ,cn_last_update_login       AS last_update_login
          ,ccd.attribute_category     AS attribute_category
          ,ccd.period_trans_qty       AS period_trans_qty
          ,ccd.period_perp_qty        AS period_perp_qty
         FROM
           cm_cmpt_dtl@t4_hon    ccd
          ,ic_item_mst_b@t4_hon  iimb
         WHERE ccd.item_id       = iimb.item_id
           AND ccd.calendar_code = gt_calendar_code -- ����v�N�x
         MINUS
         SELECT
           NULL                       AS cmpntcost_id
          ,NULL                       AS item_id
          ,iimb.item_no               AS item_no
          ,ccd.whse_code              AS whse_code
          ,ccd.calendar_code          AS calendar_code
          ,ccd.period_code            AS period_code
          ,ccd.cost_mthd_code         AS cost_mthd_code
          ,ccd.cost_cmpntcls_id       AS cost_cmpntcls_id
          ,ccd.cost_analysis_code     AS cost_analysis_code
          ,ccd.cost_level             AS cost_level
          ,ccd.cmpnt_cost             AS cmpnt_cost
          ,ccd.burden_ind             AS burden_ind
          ,ccd.fmeff_id               AS fmeff_id
          ,ccd.rollover_ind           AS rollover_ind
          ,ccd.total_qty              AS total_qty
          ,ccd.costcalc_orig          AS costcalc_orig
          ,ccd.rmcalc_type            AS rmcalc_type
          ,ccd.rollup_ref_no          AS rollup_ref_no
          ,ccd.acproc_id              AS acproc_id
          ,ccd.trans_cnt              AS trans_cnt
          ,ccd.text_code              AS text_code
          ,ccd.delete_mark            AS delete_mark
          ,cn_request_id              AS request_id
          ,cn_program_application_id  AS program_application_id
          ,cn_program_id              AS program_id
          ,cd_program_update_date     AS program_update_date
          ,ccd.attribute1             AS attribute1
          ,ccd.attribute2             AS attribute2
          ,ccd.attribute3             AS attribute3
          ,ccd.attribute4             AS attribute4
          ,ccd.attribute5             AS attribute5
          ,ccd.attribute6             AS attribute6
          ,ccd.attribute7             AS attribute7
          ,ccd.attribute8             AS attribute8
          ,ccd.attribute9             AS attribute9
          ,ccd.attribute10            AS attribute10
          ,ccd.attribute11            AS attribute11
          ,ccd.attribute12            AS attribute12
          ,ccd.attribute13            AS attribute13
          ,ccd.attribute14            AS attribute14
          ,ccd.attribute15            AS attribute15
          ,ccd.attribute16            AS attribute16
          ,ccd.attribute17            AS attribute17
          ,ccd.attribute18            AS attribute18
          ,ccd.attribute19            AS attribute19
          ,ccd.attribute20            AS attribute20
          ,ccd.attribute21            AS attribute21
          ,ccd.attribute22            AS attribute22
          ,ccd.attribute23            AS attribute23
          ,ccd.attribute24            AS attribute24
          ,ccd.attribute25            AS attribute25
          ,ccd.attribute26            AS attribute26
          ,ccd.attribute27            AS attribute27
          ,ccd.attribute28            AS attribute28
          ,ccd.attribute29            AS attribute29
          ,ccd.attribute30            AS attribute30
          ,cn_created_by              AS created_by
          ,cd_creation_date           AS creation_date
          ,cn_last_updated_by         AS last_updated_by
          ,cd_last_update_date        AS last_update_date
          ,cn_last_update_login       AS last_update_login
          ,ccd.attribute_category     AS attribute_category
          ,ccd.period_trans_qty       AS period_trans_qty
          ,ccd.period_perp_qty        AS period_perp_qty
         FROM
           cm_cmpt_dtl    ccd
          ,ic_item_mst_b  iimb
         WHERE ccd.item_id       = iimb.item_id
           AND ccd.calendar_code = gt_calendar_code -- ����v�N�x
         ) a
    WHERE
        EXISTS (
            SELECT 1
            FROM   cm_cmpt_dtl    b
                  ,ic_item_mst_b  b2
            WHERE  b.item_id          = b2.item_id
              AND  b2.item_no         = a.item_no
              AND  b.calendar_code    = a.calendar_code
              AND  b.cost_cmpntcls_id = a.cost_cmpntcls_id
        )
  ;
  TYPE get_ccd_ttype IS TABLE OF xxccp_cm_cmpt_dtl%ROWTYPE INDEX BY BINARY_INTEGER;
  get_ccd_tab get_ccd_ttype;
--
  -- DISC�i�ڃ}�X�^�������oSQL
  CURSOR get_msib_cur
  IS
    --�ǉ�
    SELECT
      a.inventory_item_id              AS inventory_item_id
     ,a.organization_id                AS organization_id
     ,a2.organization_code             AS organization_code
     -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
     ,cd_last_update_date              AS last_update_date
     ,cn_last_updated_by               AS last_updated_by
     ,cd_creation_date                 AS creation_date
     ,cn_created_by                    AS created_by
     ,cn_last_update_login             AS last_update_login
     --
     ,a.summary_flag                   AS summary_flag
     ,a.enabled_flag                   AS enabled_flag
     ,a.start_date_active              AS start_date_active
     ,a.end_date_active                AS end_date_active
     ,a.description                    AS description
     ,a.buyer_id                       AS buyer_id
     ,a.accounting_rule_id             AS accounting_rule_id
     ,a.invoicing_rule_id              AS invoicing_rule_id
     ,a.segment1                       AS segment1
     ,a.segment2                       AS segment2
     ,a.segment3                       AS segment3
     ,a.segment4                       AS segment4
     ,a.segment5                       AS segment5
     ,a.segment6                       AS segment6
     ,a.segment7                       AS segment7
     ,a.segment8                       AS segment8
     ,a.segment9                       AS segment9
     ,a.segment10                      AS segment10
     ,a.segment11                      AS segment11
     ,a.segment12                      AS segment12
     ,a.segment13                      AS segment13
     ,a.segment14                      AS segment14
     ,a.segment15                      AS segment15
     ,a.segment16                      AS segment16
     ,a.segment17                      AS segment17
     ,a.segment18                      AS segment18
     ,a.segment19                      AS segment19
     ,a.segment20                      AS segment20
     ,a.attribute_category             AS attribute_category
     ,a.attribute1                     AS attribute1
     ,a.attribute2                     AS attribute2
     ,a.attribute3                     AS attribute3
     ,a.attribute4                     AS attribute4
     ,a.attribute5                     AS attribute5
     ,a.attribute6                     AS attribute6
     ,a.attribute7                     AS attribute7
     ,a.attribute8                     AS attribute8
     ,a.attribute9                     AS attribute9
     ,a.attribute10                    AS attribute10
     ,a.attribute11                    AS attribute11
     ,a.attribute12                    AS attribute12
     ,a.attribute13                    AS attribute13
     ,a.attribute14                    AS attribute14
     ,a.attribute15                    AS attribute15
     ,a.purchasing_item_flag           AS purchasing_item_flag
     ,a.shippable_item_flag            AS shippable_item_flag
     ,a.customer_order_flag            AS customer_order_flag
     ,a.internal_order_flag            AS internal_order_flag
     ,a.service_item_flag              AS service_item_flag
     ,a.inventory_item_flag            AS inventory_item_flag
     ,a.eng_item_flag                  AS eng_item_flag
     ,a.inventory_asset_flag           AS inventory_asset_flag
     ,a.purchasing_enabled_flag        AS purchasing_enabled_flag
     ,a.customer_order_enabled_flag    AS customer_order_enabled_flag
     ,a.internal_order_enabled_flag    AS internal_order_enabled_flag
     ,a.so_transactions_flag           AS so_transactions_flag
     ,a.mtl_transactions_enabled_flag  AS mtl_transactions_enabled_flag
     ,a.stock_enabled_flag             AS stock_enabled_flag
     ,a.bom_enabled_flag               AS bom_enabled_flag
     ,a.build_in_wip_flag              AS build_in_wip_flag
     ,a.revision_qty_control_code      AS revision_qty_control_code
     ,a.item_catalog_group_id          AS item_catalog_group_id
     ,a.catalog_status_flag            AS catalog_status_flag
     ,a.returnable_flag                AS returnable_flag
     ,a.default_shipping_org           AS default_shipping_org
     ,a.collateral_flag                AS collateral_flag
     ,a.taxable_flag                   AS taxable_flag
     ,a.qty_rcv_exception_code         AS qty_rcv_exception_code
     ,a.allow_item_desc_update_flag    AS allow_item_desc_update_flag
     ,a.inspection_required_flag       AS inspection_required_flag
     ,a.receipt_required_flag          AS receipt_required_flag
     ,a.market_price                   AS market_price
     ,a.hazard_class_id                AS hazard_class_id
     ,a.rfq_required_flag              AS rfq_required_flag
     ,a.qty_rcv_tolerance              AS qty_rcv_tolerance
     ,a.list_price_per_unit            AS list_price_per_unit
     ,a.un_number_id                   AS un_number_id
     ,a.price_tolerance_percent        AS price_tolerance_percent
     ,a.asset_category_id              AS asset_category_id
     ,a.rounding_factor                AS rounding_factor
     ,a.unit_of_issue                  AS unit_of_issue
     ,a.enforce_ship_to_location_code  AS enforce_ship_to_location_code
     ,a.allow_substitute_receipts_flag AS allow_substitute_receipts_flag
     ,a.allow_unordered_receipts_flag  AS allow_unordered_receipts_flag
     ,a.allow_express_delivery_flag    AS allow_express_delivery_flag
     ,a.days_early_receipt_allowed     AS days_early_receipt_allowed
     ,a.days_late_receipt_allowed      AS days_late_receipt_allowed
     ,a.receipt_days_exception_code    AS receipt_days_exception_code
     ,a.receiving_routing_id           AS receiving_routing_id
     ,a.invoice_close_tolerance        AS invoice_close_tolerance
     ,a.receive_close_tolerance        AS receive_close_tolerance
     ,a.auto_lot_alpha_prefix          AS auto_lot_alpha_prefix
     ,a.start_auto_lot_number          AS start_auto_lot_number
     ,a.lot_control_code               AS lot_control_code
     ,a.shelf_life_code                AS shelf_life_code
     ,a.shelf_life_days                AS shelf_life_days
     ,a.serial_number_control_code     AS serial_number_control_code
     ,a.start_auto_serial_number       AS start_auto_serial_number
     ,a.auto_serial_alpha_prefix       AS auto_serial_alpha_prefix
     ,a.source_type                    AS source_type
     ,a.source_organization_id         AS source_organization_id
     ,a.source_subinventory            AS source_subinventory
     ,a.expense_account                AS expense_account
     ,a.encumbrance_account            AS encumbrance_account
     ,a.restrict_subinventories_code   AS restrict_subinventories_code
     ,a.unit_weight                    AS unit_weight
     ,a.weight_uom_code                AS weight_uom_code
     ,a.volume_uom_code                AS volume_uom_code
     ,a.unit_volume                    AS unit_volume
     ,a.restrict_locators_code         AS restrict_locators_code
     ,a.location_control_code          AS location_control_code
     ,a.shrinkage_rate                 AS shrinkage_rate
     ,a.acceptable_early_days          AS acceptable_early_days
     ,a.planning_time_fence_code       AS planning_time_fence_code
     ,a.demand_time_fence_code         AS demand_time_fence_code
     ,a.lead_time_lot_size             AS lead_time_lot_size
     ,a.std_lot_size                   AS std_lot_size
     ,a.cum_manufacturing_lead_time    AS cum_manufacturing_lead_time
     ,a.overrun_percentage             AS overrun_percentage
     ,a.mrp_calculate_atp_flag         AS mrp_calculate_atp_flag
     ,a.acceptable_rate_increase       AS acceptable_rate_increase
     ,a.acceptable_rate_decrease       AS acceptable_rate_decrease
     ,a.cumulative_total_lead_time     AS cumulative_total_lead_time
     ,a.planning_time_fence_days       AS planning_time_fence_days
     ,a.demand_time_fence_days         AS demand_time_fence_days
     ,a.end_assembly_pegging_flag      AS end_assembly_pegging_flag
     ,a.repetitive_planning_flag       AS repetitive_planning_flag
     ,a.planning_exception_set         AS planning_exception_set
     ,a.bom_item_type                  AS bom_item_type
     ,a.pick_components_flag           AS pick_components_flag
     ,a.replenish_to_order_flag        AS replenish_to_order_flag
     ,a.base_item_id                   AS base_item_id
     ,a.atp_components_flag            AS atp_components_flag
     ,a.atp_flag                       AS atp_flag
     ,a.fixed_lead_time                AS fixed_lead_time
     ,a.variable_lead_time             AS variable_lead_time
     ,a.wip_supply_locator_id          AS wip_supply_locator_id
     ,a.wip_supply_type                AS wip_supply_type
     ,a.wip_supply_subinventory        AS wip_supply_subinventory
     ,a.primary_uom_code               AS primary_uom_code
     ,a.primary_unit_of_measure        AS primary_unit_of_measure
     ,a.allowed_units_lookup_code      AS allowed_units_lookup_code
     ,1                                AS cost_of_sales_account
     ,1                                AS sales_account
     ,a.default_include_in_rollup_flag AS default_include_in_rollup_flag
     ,a.inventory_item_status_code     AS inventory_item_status_code
     ,a.inventory_planning_code        AS inventory_planning_code
     ,a.planner_code                   AS planner_code
     ,a.planning_make_buy_code         AS planning_make_buy_code
     ,a.fixed_lot_multiplier           AS fixed_lot_multiplier
     ,a.rounding_control_type          AS rounding_control_type
     ,a.carrying_cost                  AS carrying_cost
     ,a.postprocessing_lead_time       AS postprocessing_lead_time
     ,a.preprocessing_lead_time        AS preprocessing_lead_time
     ,a.full_lead_time                 AS full_lead_time
     ,a.order_cost                     AS order_cost
     ,a.mrp_safety_stock_percent       AS mrp_safety_stock_percent
     ,a.mrp_safety_stock_code          AS mrp_safety_stock_code
     ,a.min_minmax_quantity            AS min_minmax_quantity
     ,a.max_minmax_quantity            AS max_minmax_quantity
     ,a.minimum_order_quantity         AS minimum_order_quantity
     ,a.fixed_order_quantity           AS fixed_order_quantity
     ,a.fixed_days_supply              AS fixed_days_supply
     ,a.maximum_order_quantity         AS maximum_order_quantity
     ,a.atp_rule_id                    AS atp_rule_id
     ,a.picking_rule_id                AS picking_rule_id
     ,NULL                             AS reservable_type
     ,a.positive_measurement_error     AS positive_measurement_error
     ,a.negative_measurement_error     AS negative_measurement_error
     ,a.engineering_ecn_code           AS engineering_ecn_code
     ,a.engineering_item_id            AS engineering_item_id
     ,a.engineering_date               AS engineering_date
     ,a.service_starting_delay         AS service_starting_delay
     ,a.vendor_warranty_flag           AS vendor_warranty_flag
     ,a.serviceable_component_flag     AS serviceable_component_flag
     ,a.serviceable_product_flag       AS serviceable_product_flag
     ,a.base_warranty_service_id       AS base_warranty_service_id
     ,a.payment_terms_id               AS payment_terms_id
     ,a.preventive_maintenance_flag    AS preventive_maintenance_flag
     ,a.primary_specialist_id          AS primary_specialist_id
     ,a.secondary_specialist_id        AS secondary_specialist_id
     ,a.serviceable_item_class_id      AS serviceable_item_class_id
     ,a.time_billable_flag             AS time_billable_flag
     ,a.material_billable_flag         AS material_billable_flag
     ,a.expense_billable_flag          AS expense_billable_flag
     ,a.prorate_service_flag           AS prorate_service_flag
     ,a.coverage_schedule_id           AS coverage_schedule_id
     ,a.service_duration_period_code   AS service_duration_period_code
     ,a.service_duration               AS service_duration
     ,a.warranty_vendor_id             AS warranty_vendor_id
     ,a.max_warranty_amount            AS max_warranty_amount
     ,a.response_time_period_code      AS response_time_period_code
     ,a.response_time_value            AS response_time_value
     ,a.new_revision_code              AS new_revision_code
     ,a.invoiceable_item_flag          AS invoiceable_item_flag
     ,a.tax_code                       AS tax_code
     ,a.invoice_enabled_flag           AS invoice_enabled_flag
     ,a.must_use_approved_vendor_flag  AS must_use_approved_vendor_flag
     -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
     ,cn_request_id                    AS request_id
     ,cn_program_application_id        AS program_application_id
     ,cn_program_id                    AS program_id
     ,cd_program_update_date           AS program_update_date
     --
     ,a.outside_operation_flag         AS outside_operation_flag
     ,a.outside_operation_uom_type     AS outside_operation_uom_type
     ,a.safety_stock_bucket_days       AS safety_stock_bucket_days
     ,a.auto_reduce_mps                AS auto_reduce_mps
     ,a.costing_enabled_flag           AS costing_enabled_flag
     ,a.auto_created_config_flag       AS auto_created_config_flag
     ,a.cycle_count_enabled_flag       AS cycle_count_enabled_flag
     ,a.item_type                      AS item_type
     ,a.model_config_clause_name       AS model_config_clause_name
     ,a.ship_model_complete_flag       AS ship_model_complete_flag
     ,a.mrp_planning_code              AS mrp_planning_code
     ,a.return_inspection_requirement  AS return_inspection_requirement
     ,a.ato_forecast_control           AS ato_forecast_control
     ,a.release_time_fence_code        AS release_time_fence_code
     ,a.release_time_fence_days        AS release_time_fence_days
     ,a.container_item_flag            AS container_item_flag
     ,a.vehicle_item_flag              AS vehicle_item_flag
     ,a.maximum_load_weight            AS maximum_load_weight
     ,a.minimum_fill_percent           AS minimum_fill_percent
     ,a.container_type_code            AS container_type_code
     ,a.internal_volume                AS internal_volume
     ,a.wh_update_date                 AS wh_update_date
     ,a.product_family_item_id         AS product_family_item_id
     ,a.global_attribute_category      AS global_attribute_category
     ,a.global_attribute1              AS global_attribute1
     ,a.global_attribute2              AS global_attribute2
     ,a.global_attribute3              AS global_attribute3
     ,a.global_attribute4              AS global_attribute4
     ,a.global_attribute5              AS global_attribute5
     ,a.global_attribute6              AS global_attribute6
     ,a.global_attribute7              AS global_attribute7
     ,a.global_attribute8              AS global_attribute8
     ,a.global_attribute9              AS global_attribute9
     ,a.global_attribute10             AS global_attribute10
     ,a.purchasing_tax_code            AS purchasing_tax_code
     ,a.overcompletion_tolerance_type  AS overcompletion_tolerance_type
     ,a.overcompletion_tolerance_value AS overcompletion_tolerance_value
     ,a.effectivity_control            AS effectivity_control
     ,a.check_shortages_flag           AS check_shortages_flag
     ,a.over_shipment_tolerance        AS over_shipment_tolerance
     ,a.under_shipment_tolerance       AS under_shipment_tolerance
     ,a.over_return_tolerance          AS over_return_tolerance
     ,a.under_return_tolerance         AS under_return_tolerance
     ,a.equipment_type                 AS equipment_type
     ,a.recovered_part_disp_code       AS recovered_part_disp_code
     ,a.defect_tracking_on_flag        AS defect_tracking_on_flag
     ,a.usage_item_flag                AS usage_item_flag
     ,a.event_flag                     AS event_flag
     ,a.electronic_flag                AS electronic_flag
     ,a.downloadable_flag              AS downloadable_flag
     ,a.vol_discount_exempt_flag       AS vol_discount_exempt_flag
     ,a.coupon_exempt_flag             AS coupon_exempt_flag
     ,a.comms_nl_trackable_flag        AS comms_nl_trackable_flag
     ,a.asset_creation_code            AS asset_creation_code
     ,a.comms_activation_reqd_flag     AS comms_activation_reqd_flag
     ,a.orderable_on_web_flag          AS orderable_on_web_flag
     ,a.back_orderable_flag            AS back_orderable_flag
     ,a.web_status                     AS web_status
     ,a.indivisible_flag               AS indivisible_flag
     ,a.dimension_uom_code             AS dimension_uom_code
     ,a.unit_length                    AS unit_length
     ,a.unit_width                     AS unit_width
     ,a.unit_height                    AS unit_height
     ,a.bulk_picked_flag               AS bulk_picked_flag
     ,a.lot_status_enabled             AS lot_status_enabled
     ,a.default_lot_status_id          AS default_lot_status_id
     ,a.serial_status_enabled          AS serial_status_enabled
     ,a.default_serial_status_id       AS default_serial_status_id
     ,a.lot_split_enabled              AS lot_split_enabled
     ,a.lot_merge_enabled              AS lot_merge_enabled
     ,a.inventory_carry_penalty        AS inventory_carry_penalty
     ,a.operation_slack_penalty        AS operation_slack_penalty
     ,a.financing_allowed_flag         AS financing_allowed_flag
     ,a.eam_item_type                  AS eam_item_type
     ,a.eam_activity_type_code         AS eam_activity_type_code
     ,a.eam_activity_cause_code        AS eam_activity_cause_code
     ,a.eam_act_notification_flag      AS eam_act_notification_flag
     ,a.eam_act_shutdown_status        AS eam_act_shutdown_status
     ,a.dual_uom_control               AS dual_uom_control
     ,a.secondary_uom_code             AS secondary_uom_code
     ,a.dual_uom_deviation_high        AS dual_uom_deviation_high
     ,a.dual_uom_deviation_low         AS dual_uom_deviation_low
     ,a.contract_item_type_code        AS contract_item_type_code
     ,a.subscription_depend_flag       AS subscription_depend_flag
     ,a.serv_req_enabled_code          AS serv_req_enabled_code
     ,a.serv_billing_enabled_flag      AS serv_billing_enabled_flag
     ,a.serv_importance_level          AS serv_importance_level
     ,a.planned_inv_point_flag         AS planned_inv_point_flag
     ,a.lot_translate_enabled          AS lot_translate_enabled
     ,a.default_so_source_type         AS default_so_source_type
     ,a.create_supply_flag             AS create_supply_flag
     ,a.substitution_window_code       AS substitution_window_code
     ,a.substitution_window_days       AS substitution_window_days
     ,a.ib_item_instance_class         AS ib_item_instance_class
     ,a.config_model_type              AS config_model_type
     ,a.lot_substitution_enabled       AS lot_substitution_enabled
     ,a.minimum_license_quantity       AS minimum_license_quantity
     ,a.eam_activity_source_code       AS eam_activity_source_code
     ,a.lifecycle_id                   AS lifecycle_id
     ,a.current_phase_id               AS current_phase_id
     ,1                                AS object_version_number
     ,a.tracking_quantity_ind          AS tracking_quantity_ind
     ,a.ont_pricing_qty_source         AS ont_pricing_qty_source
     ,a.secondary_default_ind          AS secondary_default_ind
     ,a.option_specific_sourced        AS option_specific_sourced
     ,a.approval_status                AS approval_status
     ,a.vmi_minimum_units              AS vmi_minimum_units
     ,a.vmi_minimum_days               AS vmi_minimum_days
     ,a.vmi_maximum_units              AS vmi_maximum_units
     ,a.vmi_maximum_days               AS vmi_maximum_days
     ,a.vmi_fixed_order_quantity       AS vmi_fixed_order_quantity
     ,a.so_authorization_flag          AS so_authorization_flag
     ,a.consigned_flag                 AS consigned_flag
     ,a.asn_autoexpire_flag            AS asn_autoexpire_flag
     ,a.vmi_forecast_type              AS vmi_forecast_type
     ,a.forecast_horizon               AS forecast_horizon
     ,a.exclude_from_budget_flag       AS exclude_from_budget_flag
     ,a.days_tgt_inv_supply            AS days_tgt_inv_supply
     ,a.days_tgt_inv_window            AS days_tgt_inv_window
     ,a.days_max_inv_supply            AS days_max_inv_supply
     ,a.days_max_inv_window            AS days_max_inv_window
     ,a.drp_planned_flag               AS drp_planned_flag
     ,a.critical_component_flag        AS critical_component_flag
     ,a.continous_transfer             AS continous_transfer
     ,a.convergence                    AS convergence
     ,a.divergence                     AS divergence
     ,a.config_orgs                    AS config_orgs
     ,a.config_match                   AS config_match
     ,a.global_attribute11             AS global_attribute11
     ,a.global_attribute12             AS global_attribute12
     ,a.global_attribute13             AS global_attribute13
     ,a.global_attribute14             AS global_attribute14
     ,a.global_attribute15             AS global_attribute15
     ,a.global_attribute16             AS global_attribute16
     ,a.global_attribute17             AS global_attribute17
     ,a.global_attribute18             AS global_attribute18
     ,a.global_attribute19             AS global_attribute19
     ,a.global_attribute20             AS global_attribute20
     ,'I'                              AS record_type
    FROM
      (SELECT m.*
       FROM   mtl_system_items_b@t4_hon m
       WHERE  m.organization_id IN ( gt_mst_org_id_hon ,gt_org_id_hon )
      ) a
     ,mtl_parameters@t4_hon      a2
    WHERE a.organization_id    = a2.organization_id
      AND NOT EXISTS(
        SELECT 1
        FROM   (SELECT m.*
                FROM   mtl_system_items_b m
                WHERE  m.organization_id IN ( gt_mst_org_id_t4 ,gt_org_id_t4 )
               )                  b
              ,mtl_parameters     b2
        WHERE  b.organization_id    = b2.organization_id
          AND  b.segment1           = a.segment1
          AND  b2.organization_code = a2.organization_code
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.inventory_item_id              AS inventory_item_id
     ,a.organization_id                AS organization_id
     ,a.organization_code              AS organization_code
     ,a.last_update_date               AS last_update_date
     ,a.last_updated_by                AS last_updated_by
     ,a.creation_date                  AS creation_date
     ,a.created_by                     AS created_by
     ,a.last_update_login              AS last_update_login
     ,a.summary_flag                   AS summary_flag
     ,a.enabled_flag                   AS enabled_flag
     ,a.start_date_active              AS start_date_active
     ,a.end_date_active                AS end_date_active
     ,a.description                    AS description
     ,a.buyer_id                       AS buyer_id
     ,a.accounting_rule_id             AS accounting_rule_id
     ,a.invoicing_rule_id              AS invoicing_rule_id
     ,a.segment1                       AS segment1
     ,a.segment2                       AS segment2
     ,a.segment3                       AS segment3
     ,a.segment4                       AS segment4
     ,a.segment5                       AS segment5
     ,a.segment6                       AS segment6
     ,a.segment7                       AS segment7
     ,a.segment8                       AS segment8
     ,a.segment9                       AS segment9
     ,a.segment10                      AS segment10
     ,a.segment11                      AS segment11
     ,a.segment12                      AS segment12
     ,a.segment13                      AS segment13
     ,a.segment14                      AS segment14
     ,a.segment15                      AS segment15
     ,a.segment16                      AS segment16
     ,a.segment17                      AS segment17
     ,a.segment18                      AS segment18
     ,a.segment19                      AS segment19
     ,a.segment20                      AS segment20
     ,a.attribute_category             AS attribute_category
     ,a.attribute1                     AS attribute1
     ,a.attribute2                     AS attribute2
     ,a.attribute3                     AS attribute3
     ,a.attribute4                     AS attribute4
     ,a.attribute5                     AS attribute5
     ,a.attribute6                     AS attribute6
     ,a.attribute7                     AS attribute7
     ,a.attribute8                     AS attribute8
     ,a.attribute9                     AS attribute9
     ,a.attribute10                    AS attribute10
     ,a.attribute11                    AS attribute11
     ,a.attribute12                    AS attribute12
     ,a.attribute13                    AS attribute13
     ,a.attribute14                    AS attribute14
     ,a.attribute15                    AS attribute15
     ,a.purchasing_item_flag           AS purchasing_item_flag
     ,a.shippable_item_flag            AS shippable_item_flag
     ,a.customer_order_flag            AS customer_order_flag
     ,a.internal_order_flag            AS internal_order_flag
     ,a.service_item_flag              AS service_item_flag
     ,a.inventory_item_flag            AS inventory_item_flag
     ,a.eng_item_flag                  AS eng_item_flag
     ,a.inventory_asset_flag           AS inventory_asset_flag
     ,a.purchasing_enabled_flag        AS purchasing_enabled_flag
     ,a.customer_order_enabled_flag    AS customer_order_enabled_flag
     ,a.internal_order_enabled_flag    AS internal_order_enabled_flag
     ,a.so_transactions_flag           AS so_transactions_flag
     ,a.mtl_transactions_enabled_flag  AS mtl_transactions_enabled_flag
     ,a.stock_enabled_flag             AS stock_enabled_flag
     ,a.bom_enabled_flag               AS bom_enabled_flag
     ,a.build_in_wip_flag              AS build_in_wip_flag
     ,a.revision_qty_control_code      AS revision_qty_control_code
     ,a.item_catalog_group_id          AS item_catalog_group_id
     ,a.catalog_status_flag            AS catalog_status_flag
     ,a.returnable_flag                AS returnable_flag
     ,a.default_shipping_org           AS default_shipping_org
     ,a.collateral_flag                AS collateral_flag
     ,a.taxable_flag                   AS taxable_flag
     ,a.qty_rcv_exception_code         AS qty_rcv_exception_code
     ,a.allow_item_desc_update_flag    AS allow_item_desc_update_flag
     ,a.inspection_required_flag       AS inspection_required_flag
     ,a.receipt_required_flag          AS receipt_required_flag
     ,a.market_price                   AS market_price
     ,a.hazard_class_id                AS hazard_class_id
     ,a.rfq_required_flag              AS rfq_required_flag
     ,a.qty_rcv_tolerance              AS qty_rcv_tolerance
     ,a.list_price_per_unit            AS list_price_per_unit
     ,a.un_number_id                   AS un_number_id
     ,a.price_tolerance_percent        AS price_tolerance_percent
     ,a.asset_category_id              AS asset_category_id
     ,a.rounding_factor                AS rounding_factor
     ,a.unit_of_issue                  AS unit_of_issue
     ,a.enforce_ship_to_location_code  AS enforce_ship_to_location_code
     ,a.allow_substitute_receipts_flag AS allow_substitute_receipts_flag
     ,a.allow_unordered_receipts_flag  AS allow_unordered_receipts_flag
     ,a.allow_express_delivery_flag    AS allow_express_delivery_flag
     ,a.days_early_receipt_allowed     AS days_early_receipt_allowed
     ,a.days_late_receipt_allowed      AS days_late_receipt_allowed
     ,a.receipt_days_exception_code    AS receipt_days_exception_code
     ,a.receiving_routing_id           AS receiving_routing_id
     ,a.invoice_close_tolerance        AS invoice_close_tolerance
     ,a.receive_close_tolerance        AS receive_close_tolerance
     ,a.auto_lot_alpha_prefix          AS auto_lot_alpha_prefix
     ,a.start_auto_lot_number          AS start_auto_lot_number
     ,a.lot_control_code               AS lot_control_code
     ,a.shelf_life_code                AS shelf_life_code
     ,a.shelf_life_days                AS shelf_life_days
     ,a.serial_number_control_code     AS serial_number_control_code
     ,a.start_auto_serial_number       AS start_auto_serial_number
     ,a.auto_serial_alpha_prefix       AS auto_serial_alpha_prefix
     ,a.source_type                    AS source_type
     ,a.source_organization_id         AS source_organization_id
     ,a.source_subinventory            AS source_subinventory
     ,a.expense_account                AS expense_account
     ,a.encumbrance_account            AS encumbrance_account
     ,a.restrict_subinventories_code   AS restrict_subinventories_code
     ,a.unit_weight                    AS unit_weight
     ,a.weight_uom_code                AS weight_uom_code
     ,a.volume_uom_code                AS volume_uom_code
     ,a.unit_volume                    AS unit_volume
     ,a.restrict_locators_code         AS restrict_locators_code
     ,a.location_control_code          AS location_control_code
     ,a.shrinkage_rate                 AS shrinkage_rate
     ,a.acceptable_early_days          AS acceptable_early_days
     ,a.planning_time_fence_code       AS planning_time_fence_code
     ,a.demand_time_fence_code         AS demand_time_fence_code
     ,a.lead_time_lot_size             AS lead_time_lot_size
     ,a.std_lot_size                   AS std_lot_size
     ,a.cum_manufacturing_lead_time    AS cum_manufacturing_lead_time
     ,a.overrun_percentage             AS overrun_percentage
     ,a.mrp_calculate_atp_flag         AS mrp_calculate_atp_flag
     ,a.acceptable_rate_increase       AS acceptable_rate_increase
     ,a.acceptable_rate_decrease       AS acceptable_rate_decrease
     ,a.cumulative_total_lead_time     AS cumulative_total_lead_time
     ,a.planning_time_fence_days       AS planning_time_fence_days
     ,a.demand_time_fence_days         AS demand_time_fence_days
     ,a.end_assembly_pegging_flag      AS end_assembly_pegging_flag
     ,a.repetitive_planning_flag       AS repetitive_planning_flag
     ,a.planning_exception_set         AS planning_exception_set
     ,a.bom_item_type                  AS bom_item_type
     ,a.pick_components_flag           AS pick_components_flag
     ,a.replenish_to_order_flag        AS replenish_to_order_flag
     ,a.base_item_id                   AS base_item_id
     ,a.atp_components_flag            AS atp_components_flag
     ,a.atp_flag                       AS atp_flag
     ,a.fixed_lead_time                AS fixed_lead_time
     ,a.variable_lead_time             AS variable_lead_time
     ,a.wip_supply_locator_id          AS wip_supply_locator_id
     ,a.wip_supply_type                AS wip_supply_type
     ,a.wip_supply_subinventory        AS wip_supply_subinventory
     ,a.primary_uom_code               AS primary_uom_code
     ,a.primary_unit_of_measure        AS primary_unit_of_measure
     ,a.allowed_units_lookup_code      AS allowed_units_lookup_code
     ,1                                AS cost_of_sales_account
     ,1                                AS sales_account
     ,a.default_include_in_rollup_flag AS default_include_in_rollup_flag
     ,a.inventory_item_status_code     AS inventory_item_status_code
     ,a.inventory_planning_code        AS inventory_planning_code
     ,a.planner_code                   AS planner_code
     ,a.planning_make_buy_code         AS planning_make_buy_code
     ,a.fixed_lot_multiplier           AS fixed_lot_multiplier
     ,a.rounding_control_type          AS rounding_control_type
     ,a.carrying_cost                  AS carrying_cost
     ,a.postprocessing_lead_time       AS postprocessing_lead_time
     ,a.preprocessing_lead_time        AS preprocessing_lead_time
     ,a.full_lead_time                 AS full_lead_time
     ,a.order_cost                     AS order_cost
     ,a.mrp_safety_stock_percent       AS mrp_safety_stock_percent
     ,a.mrp_safety_stock_code          AS mrp_safety_stock_code
     ,a.min_minmax_quantity            AS min_minmax_quantity
     ,a.max_minmax_quantity            AS max_minmax_quantity
     ,a.minimum_order_quantity         AS minimum_order_quantity
     ,a.fixed_order_quantity           AS fixed_order_quantity
     ,a.fixed_days_supply              AS fixed_days_supply
     ,a.maximum_order_quantity         AS maximum_order_quantity
     ,a.atp_rule_id                    AS atp_rule_id
     ,a.picking_rule_id                AS picking_rule_id
     ,a.reservable_type                AS reservable_type
     ,a.positive_measurement_error     AS positive_measurement_error
     ,a.negative_measurement_error     AS negative_measurement_error
     ,a.engineering_ecn_code           AS engineering_ecn_code
     ,a.engineering_item_id            AS engineering_item_id
     ,a.engineering_date               AS engineering_date
     ,a.service_starting_delay         AS service_starting_delay
     ,a.vendor_warranty_flag           AS vendor_warranty_flag
     ,a.serviceable_component_flag     AS serviceable_component_flag
     ,a.serviceable_product_flag       AS serviceable_product_flag
     ,a.base_warranty_service_id       AS base_warranty_service_id
     ,a.payment_terms_id               AS payment_terms_id
     ,a.preventive_maintenance_flag    AS preventive_maintenance_flag
     ,a.primary_specialist_id          AS primary_specialist_id
     ,a.secondary_specialist_id        AS secondary_specialist_id
     ,a.serviceable_item_class_id      AS serviceable_item_class_id
     ,a.time_billable_flag             AS time_billable_flag
     ,a.material_billable_flag         AS material_billable_flag
     ,a.expense_billable_flag          AS expense_billable_flag
     ,a.prorate_service_flag           AS prorate_service_flag
     ,a.coverage_schedule_id           AS coverage_schedule_id
     ,a.service_duration_period_code   AS service_duration_period_code
     ,a.service_duration               AS service_duration
     ,a.warranty_vendor_id             AS warranty_vendor_id
     ,a.max_warranty_amount            AS max_warranty_amount
     ,a.response_time_period_code      AS response_time_period_code
     ,a.response_time_value            AS response_time_value
     ,a.new_revision_code              AS new_revision_code
     ,a.invoiceable_item_flag          AS invoiceable_item_flag
     ,a.tax_code                       AS tax_code
     ,a.invoice_enabled_flag           AS invoice_enabled_flag
     ,a.must_use_approved_vendor_flag  AS must_use_approved_vendor_flag
     ,a.request_id                     AS request_id
     ,a.program_application_id         AS program_application_id
     ,a.program_id                     AS program_id
     ,a.program_update_date            AS program_update_date
     ,a.outside_operation_flag         AS outside_operation_flag
     ,a.outside_operation_uom_type     AS outside_operation_uom_type
     ,a.safety_stock_bucket_days       AS safety_stock_bucket_days
     ,a.auto_reduce_mps                AS auto_reduce_mps
     ,a.costing_enabled_flag           AS costing_enabled_flag
     ,a.auto_created_config_flag       AS auto_created_config_flag
     ,a.cycle_count_enabled_flag       AS cycle_count_enabled_flag
     ,a.item_type                      AS item_type
     ,a.model_config_clause_name       AS model_config_clause_name
     ,a.ship_model_complete_flag       AS ship_model_complete_flag
     ,a.mrp_planning_code              AS mrp_planning_code
     ,a.return_inspection_requirement  AS return_inspection_requirement
     ,a.ato_forecast_control           AS ato_forecast_control
     ,a.release_time_fence_code        AS release_time_fence_code
     ,a.release_time_fence_days        AS release_time_fence_days
     ,a.container_item_flag            AS container_item_flag
     ,a.vehicle_item_flag              AS vehicle_item_flag
     ,a.maximum_load_weight            AS maximum_load_weight
     ,a.minimum_fill_percent           AS minimum_fill_percent
     ,a.container_type_code            AS container_type_code
     ,a.internal_volume                AS internal_volume
     ,a.wh_update_date                 AS wh_update_date
     ,a.product_family_item_id         AS product_family_item_id
     ,a.global_attribute_category      AS global_attribute_category
     ,a.global_attribute1              AS global_attribute1
     ,a.global_attribute2              AS global_attribute2
     ,a.global_attribute3              AS global_attribute3
     ,a.global_attribute4              AS global_attribute4
     ,a.global_attribute5              AS global_attribute5
     ,a.global_attribute6              AS global_attribute6
     ,a.global_attribute7              AS global_attribute7
     ,a.global_attribute8              AS global_attribute8
     ,a.global_attribute9              AS global_attribute9
     ,a.global_attribute10             AS global_attribute10
     ,a.purchasing_tax_code            AS purchasing_tax_code
     ,a.overcompletion_tolerance_type  AS overcompletion_tolerance_type
     ,a.overcompletion_tolerance_value AS overcompletion_tolerance_value
     ,a.effectivity_control            AS effectivity_control
     ,a.check_shortages_flag           AS check_shortages_flag
     ,a.over_shipment_tolerance        AS over_shipment_tolerance
     ,a.under_shipment_tolerance       AS under_shipment_tolerance
     ,a.over_return_tolerance          AS over_return_tolerance
     ,a.under_return_tolerance         AS under_return_tolerance
     ,a.equipment_type                 AS equipment_type
     ,a.recovered_part_disp_code       AS recovered_part_disp_code
     ,a.defect_tracking_on_flag        AS defect_tracking_on_flag
     ,a.usage_item_flag                AS usage_item_flag
     ,a.event_flag                     AS event_flag
     ,a.electronic_flag                AS electronic_flag
     ,a.downloadable_flag              AS downloadable_flag
     ,a.vol_discount_exempt_flag       AS vol_discount_exempt_flag
     ,a.coupon_exempt_flag             AS coupon_exempt_flag
     ,a.comms_nl_trackable_flag        AS comms_nl_trackable_flag
     ,a.asset_creation_code            AS asset_creation_code
     ,a.comms_activation_reqd_flag     AS comms_activation_reqd_flag
     ,a.orderable_on_web_flag          AS orderable_on_web_flag
     ,a.back_orderable_flag            AS back_orderable_flag
     ,a.web_status                     AS web_status
     ,a.indivisible_flag               AS indivisible_flag
     ,a.dimension_uom_code             AS dimension_uom_code
     ,a.unit_length                    AS unit_length
     ,a.unit_width                     AS unit_width
     ,a.unit_height                    AS unit_height
     ,a.bulk_picked_flag               AS bulk_picked_flag
     ,a.lot_status_enabled             AS lot_status_enabled
     ,a.default_lot_status_id          AS default_lot_status_id
     ,a.serial_status_enabled          AS serial_status_enabled
     ,a.default_serial_status_id       AS default_serial_status_id
     ,a.lot_split_enabled              AS lot_split_enabled
     ,a.lot_merge_enabled              AS lot_merge_enabled
     ,a.inventory_carry_penalty        AS inventory_carry_penalty
     ,a.operation_slack_penalty        AS operation_slack_penalty
     ,a.financing_allowed_flag         AS financing_allowed_flag
     ,a.eam_item_type                  AS eam_item_type
     ,a.eam_activity_type_code         AS eam_activity_type_code
     ,a.eam_activity_cause_code        AS eam_activity_cause_code
     ,a.eam_act_notification_flag      AS eam_act_notification_flag
     ,a.eam_act_shutdown_status        AS eam_act_shutdown_status
     ,a.dual_uom_control               AS dual_uom_control
     ,a.secondary_uom_code             AS secondary_uom_code
     ,a.dual_uom_deviation_high        AS dual_uom_deviation_high
     ,a.dual_uom_deviation_low         AS dual_uom_deviation_low
     ,a.contract_item_type_code        AS contract_item_type_code
     ,a.subscription_depend_flag       AS subscription_depend_flag
     ,a.serv_req_enabled_code          AS serv_req_enabled_code
     ,a.serv_billing_enabled_flag      AS serv_billing_enabled_flag
     ,a.serv_importance_level          AS serv_importance_level
     ,a.planned_inv_point_flag         AS planned_inv_point_flag
     ,a.lot_translate_enabled          AS lot_translate_enabled
     ,a.default_so_source_type         AS default_so_source_type
     ,a.create_supply_flag             AS create_supply_flag
     ,a.substitution_window_code       AS substitution_window_code
     ,a.substitution_window_days       AS substitution_window_days
     ,a.ib_item_instance_class         AS ib_item_instance_class
     ,a.config_model_type              AS config_model_type
     ,a.lot_substitution_enabled       AS lot_substitution_enabled
     ,a.minimum_license_quantity       AS minimum_license_quantity
     ,a.eam_activity_source_code       AS eam_activity_source_code
     ,a.lifecycle_id                   AS lifecycle_id
     ,a.current_phase_id               AS current_phase_id
     ,1                                AS object_version_number
     ,a.tracking_quantity_ind          AS tracking_quantity_ind
     ,a.ont_pricing_qty_source         AS ont_pricing_qty_source
     ,a.secondary_default_ind          AS secondary_default_ind
     ,a.option_specific_sourced        AS option_specific_sourced
     ,a.approval_status                AS approval_status
     ,a.vmi_minimum_units              AS vmi_minimum_units
     ,a.vmi_minimum_days               AS vmi_minimum_days
     ,a.vmi_maximum_units              AS vmi_maximum_units
     ,a.vmi_maximum_days               AS vmi_maximum_days
     ,a.vmi_fixed_order_quantity       AS vmi_fixed_order_quantity
     ,a.so_authorization_flag          AS so_authorization_flag
     ,a.consigned_flag                 AS consigned_flag
     ,a.asn_autoexpire_flag            AS asn_autoexpire_flag
     ,a.vmi_forecast_type              AS vmi_forecast_type
     ,a.forecast_horizon               AS forecast_horizon
     ,a.exclude_from_budget_flag       AS exclude_from_budget_flag
     ,a.days_tgt_inv_supply            AS days_tgt_inv_supply
     ,a.days_tgt_inv_window            AS days_tgt_inv_window
     ,a.days_max_inv_supply            AS days_max_inv_supply
     ,a.days_max_inv_window            AS days_max_inv_window
     ,a.drp_planned_flag               AS drp_planned_flag
     ,a.critical_component_flag        AS critical_component_flag
     ,a.continous_transfer             AS continous_transfer
     ,a.convergence                    AS convergence
     ,a.divergence                     AS divergence
     ,a.config_orgs                    AS config_orgs
     ,a.config_match                   AS config_match
     ,a.global_attribute11             AS global_attribute11
     ,a.global_attribute12             AS global_attribute12
     ,a.global_attribute13             AS global_attribute13
     ,a.global_attribute14             AS global_attribute14
     ,a.global_attribute15             AS global_attribute15
     ,a.global_attribute16             AS global_attribute16
     ,a.global_attribute17             AS global_attribute17
     ,a.global_attribute18             AS global_attribute18
     ,a.global_attribute19             AS global_attribute19
     ,a.global_attribute20             AS global_attribute20
     ,'U'                              AS record_type
    FROM(
      SELECT
        NULL                                AS inventory_item_id
       ,NULL                                AS organization_id
       ,mp.organization_code                AS organization_code
       -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
       ,cd_last_update_date                 AS last_update_date
       ,cn_last_updated_by                  AS last_updated_by
       ,cd_creation_date                    AS creation_date
       ,cn_created_by                       AS created_by
       ,cn_last_update_login                AS last_update_login
       --
       ,msib.summary_flag                   AS summary_flag
       ,msib.enabled_flag                   AS enabled_flag
       ,msib.start_date_active              AS start_date_active
       ,msib.end_date_active                AS end_date_active
       ,msib.description                    AS description
       ,msib.buyer_id                       AS buyer_id
       ,msib.accounting_rule_id             AS accounting_rule_id
       ,msib.invoicing_rule_id              AS invoicing_rule_id
       ,msib.segment1                       AS segment1
       ,msib.segment2                       AS segment2
       ,msib.segment3                       AS segment3
       ,msib.segment4                       AS segment4
       ,msib.segment5                       AS segment5
       ,msib.segment6                       AS segment6
       ,msib.segment7                       AS segment7
       ,msib.segment8                       AS segment8
       ,msib.segment9                       AS segment9
       ,msib.segment10                      AS segment10
       ,msib.segment11                      AS segment11
       ,msib.segment12                      AS segment12
       ,msib.segment13                      AS segment13
       ,msib.segment14                      AS segment14
       ,msib.segment15                      AS segment15
       ,msib.segment16                      AS segment16
       ,msib.segment17                      AS segment17
       ,msib.segment18                      AS segment18
       ,msib.segment19                      AS segment19
       ,msib.segment20                      AS segment20
       ,msib.attribute_category             AS attribute_category
       ,msib.attribute1                     AS attribute1
       ,msib.attribute2                     AS attribute2
       ,msib.attribute3                     AS attribute3
       ,msib.attribute4                     AS attribute4
       ,msib.attribute5                     AS attribute5
       ,msib.attribute6                     AS attribute6
       ,msib.attribute7                     AS attribute7
       ,msib.attribute8                     AS attribute8
       ,msib.attribute9                     AS attribute9
       ,msib.attribute10                    AS attribute10
       ,msib.attribute11                    AS attribute11
       ,msib.attribute12                    AS attribute12
       ,msib.attribute13                    AS attribute13
       ,msib.attribute14                    AS attribute14
       ,msib.attribute15                    AS attribute15
       ,msib.purchasing_item_flag           AS purchasing_item_flag
       ,msib.shippable_item_flag            AS shippable_item_flag
       ,msib.customer_order_flag            AS customer_order_flag
       ,msib.internal_order_flag            AS internal_order_flag
       ,msib.service_item_flag              AS service_item_flag
       ,msib.inventory_item_flag            AS inventory_item_flag
       ,msib.eng_item_flag                  AS eng_item_flag
       ,msib.inventory_asset_flag           AS inventory_asset_flag
       ,msib.purchasing_enabled_flag        AS purchasing_enabled_flag
       ,msib.customer_order_enabled_flag    AS customer_order_enabled_flag
       ,msib.internal_order_enabled_flag    AS internal_order_enabled_flag
       ,msib.so_transactions_flag           AS so_transactions_flag
       ,msib.mtl_transactions_enabled_flag  AS mtl_transactions_enabled_flag
       ,msib.stock_enabled_flag             AS stock_enabled_flag
       ,msib.bom_enabled_flag               AS bom_enabled_flag
       ,msib.build_in_wip_flag              AS build_in_wip_flag
       ,msib.revision_qty_control_code      AS revision_qty_control_code
       ,msib.item_catalog_group_id          AS item_catalog_group_id
       ,msib.catalog_status_flag            AS catalog_status_flag
       ,msib.returnable_flag                AS returnable_flag
       ,msib.default_shipping_org           AS default_shipping_org
       ,msib.collateral_flag                AS collateral_flag
       ,msib.taxable_flag                   AS taxable_flag
       ,msib.qty_rcv_exception_code         AS qty_rcv_exception_code
       ,msib.allow_item_desc_update_flag    AS allow_item_desc_update_flag
       ,msib.inspection_required_flag       AS inspection_required_flag
       ,msib.receipt_required_flag          AS receipt_required_flag
       ,msib.market_price                   AS market_price
       ,msib.hazard_class_id                AS hazard_class_id
       ,msib.rfq_required_flag              AS rfq_required_flag
       ,msib.qty_rcv_tolerance              AS qty_rcv_tolerance
       ,msib.list_price_per_unit            AS list_price_per_unit
       ,msib.un_number_id                   AS un_number_id
       ,msib.price_tolerance_percent        AS price_tolerance_percent
       ,msib.asset_category_id              AS asset_category_id
       ,msib.rounding_factor                AS rounding_factor
       ,msib.unit_of_issue                  AS unit_of_issue
       ,msib.enforce_ship_to_location_code  AS enforce_ship_to_location_code
       ,msib.allow_substitute_receipts_flag AS allow_substitute_receipts_flag
       ,msib.allow_unordered_receipts_flag  AS allow_unordered_receipts_flag
       ,msib.allow_express_delivery_flag    AS allow_express_delivery_flag
       ,msib.days_early_receipt_allowed     AS days_early_receipt_allowed
       ,msib.days_late_receipt_allowed      AS days_late_receipt_allowed
       ,msib.receipt_days_exception_code    AS receipt_days_exception_code
       ,msib.receiving_routing_id           AS receiving_routing_id
       ,msib.invoice_close_tolerance        AS invoice_close_tolerance
       ,msib.receive_close_tolerance        AS receive_close_tolerance
       ,msib.auto_lot_alpha_prefix          AS auto_lot_alpha_prefix
       ,msib.start_auto_lot_number          AS start_auto_lot_number
       ,msib.lot_control_code               AS lot_control_code
       ,msib.shelf_life_code                AS shelf_life_code
       ,msib.shelf_life_days                AS shelf_life_days
       ,msib.serial_number_control_code     AS serial_number_control_code
       ,msib.start_auto_serial_number       AS start_auto_serial_number
       ,msib.auto_serial_alpha_prefix       AS auto_serial_alpha_prefix
       ,msib.source_type                    AS source_type
       ,msib.source_organization_id         AS source_organization_id
       ,msib.source_subinventory            AS source_subinventory
       ,msib.expense_account                AS expense_account
       ,msib.encumbrance_account            AS encumbrance_account
       ,msib.restrict_subinventories_code   AS restrict_subinventories_code
       ,msib.unit_weight                    AS unit_weight
       ,msib.weight_uom_code                AS weight_uom_code
       ,msib.volume_uom_code                AS volume_uom_code
       ,msib.unit_volume                    AS unit_volume
       ,msib.restrict_locators_code         AS restrict_locators_code
       ,msib.location_control_code          AS location_control_code
       ,msib.shrinkage_rate                 AS shrinkage_rate
       ,msib.acceptable_early_days          AS acceptable_early_days
       ,msib.planning_time_fence_code       AS planning_time_fence_code
       ,msib.demand_time_fence_code         AS demand_time_fence_code
       ,msib.lead_time_lot_size             AS lead_time_lot_size
       ,msib.std_lot_size                   AS std_lot_size
       ,msib.cum_manufacturing_lead_time    AS cum_manufacturing_lead_time
       ,msib.overrun_percentage             AS overrun_percentage
       ,msib.mrp_calculate_atp_flag         AS mrp_calculate_atp_flag
       ,msib.acceptable_rate_increase       AS acceptable_rate_increase
       ,msib.acceptable_rate_decrease       AS acceptable_rate_decrease
       ,msib.cumulative_total_lead_time     AS cumulative_total_lead_time
       ,msib.planning_time_fence_days       AS planning_time_fence_days
       ,msib.demand_time_fence_days         AS demand_time_fence_days
       ,msib.end_assembly_pegging_flag      AS end_assembly_pegging_flag
       ,msib.repetitive_planning_flag       AS repetitive_planning_flag
       ,msib.planning_exception_set         AS planning_exception_set
       ,msib.bom_item_type                  AS bom_item_type
       ,msib.pick_components_flag           AS pick_components_flag
       ,msib.replenish_to_order_flag        AS replenish_to_order_flag
       ,msib.base_item_id                   AS base_item_id
       ,msib.atp_components_flag            AS atp_components_flag
       ,msib.atp_flag                       AS atp_flag
       ,msib.fixed_lead_time                AS fixed_lead_time
       ,msib.variable_lead_time             AS variable_lead_time
       ,msib.wip_supply_locator_id          AS wip_supply_locator_id
       ,msib.wip_supply_type                AS wip_supply_type
       ,msib.wip_supply_subinventory        AS wip_supply_subinventory
       ,msib.primary_uom_code               AS primary_uom_code
       ,msib.primary_unit_of_measure        AS primary_unit_of_measure
       ,msib.allowed_units_lookup_code      AS allowed_units_lookup_code
       ,1                                   AS cost_of_sales_account
       ,1                                   AS sales_account
       ,msib.default_include_in_rollup_flag AS default_include_in_rollup_flag
       ,msib.inventory_item_status_code     AS inventory_item_status_code
       ,msib.inventory_planning_code        AS inventory_planning_code
       ,msib.planner_code                   AS planner_code
       ,msib.planning_make_buy_code         AS planning_make_buy_code
       ,msib.fixed_lot_multiplier           AS fixed_lot_multiplier
       ,msib.rounding_control_type          AS rounding_control_type
       ,msib.carrying_cost                  AS carrying_cost
       ,msib.postprocessing_lead_time       AS postprocessing_lead_time
       ,msib.preprocessing_lead_time        AS preprocessing_lead_time
       ,msib.full_lead_time                 AS full_lead_time
       ,msib.order_cost                     AS order_cost
       ,msib.mrp_safety_stock_percent       AS mrp_safety_stock_percent
       ,msib.mrp_safety_stock_code          AS mrp_safety_stock_code
       ,msib.min_minmax_quantity            AS min_minmax_quantity
       ,msib.max_minmax_quantity            AS max_minmax_quantity
       ,msib.minimum_order_quantity         AS minimum_order_quantity
       ,msib.fixed_order_quantity           AS fixed_order_quantity
       ,msib.fixed_days_supply              AS fixed_days_supply
       ,msib.maximum_order_quantity         AS maximum_order_quantity
       ,msib.atp_rule_id                    AS atp_rule_id
       ,msib.picking_rule_id                AS picking_rule_id
       ,NULL                                AS reservable_type
       ,msib.positive_measurement_error     AS positive_measurement_error
       ,msib.negative_measurement_error     AS negative_measurement_error
       ,msib.engineering_ecn_code           AS engineering_ecn_code
       ,msib.engineering_item_id            AS engineering_item_id
       ,msib.engineering_date               AS engineering_date
       ,msib.service_starting_delay         AS service_starting_delay
       ,msib.vendor_warranty_flag           AS vendor_warranty_flag
       ,msib.serviceable_component_flag     AS serviceable_component_flag
       ,msib.serviceable_product_flag       AS serviceable_product_flag
       ,msib.base_warranty_service_id       AS base_warranty_service_id
       ,msib.payment_terms_id               AS payment_terms_id
       ,msib.preventive_maintenance_flag    AS preventive_maintenance_flag
       ,msib.primary_specialist_id          AS primary_specialist_id
       ,msib.secondary_specialist_id        AS secondary_specialist_id
       ,msib.serviceable_item_class_id      AS serviceable_item_class_id
       ,msib.time_billable_flag             AS time_billable_flag
       ,msib.material_billable_flag         AS material_billable_flag
       ,msib.expense_billable_flag          AS expense_billable_flag
       ,msib.prorate_service_flag           AS prorate_service_flag
       ,msib.coverage_schedule_id           AS coverage_schedule_id
       ,msib.service_duration_period_code   AS service_duration_period_code
       ,msib.service_duration               AS service_duration
       ,msib.warranty_vendor_id             AS warranty_vendor_id
       ,msib.max_warranty_amount            AS max_warranty_amount
       ,msib.response_time_period_code      AS response_time_period_code
       ,msib.response_time_value            AS response_time_value
       ,msib.new_revision_code              AS new_revision_code
       ,msib.invoiceable_item_flag          AS invoiceable_item_flag
       ,msib.tax_code                       AS tax_code
       ,msib.invoice_enabled_flag           AS invoice_enabled_flag
       ,msib.must_use_approved_vendor_flag  AS must_use_approved_vendor_flag
       -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
       ,cn_request_id                       AS request_id
       ,cn_program_application_id           AS program_application_id
       ,cn_program_id                       AS program_id
       ,cd_program_update_date              AS program_update_date
       --
       ,msib.outside_operation_flag         AS outside_operation_flag
       ,msib.outside_operation_uom_type     AS outside_operation_uom_type
       ,msib.safety_stock_bucket_days       AS safety_stock_bucket_days
       ,msib.auto_reduce_mps                AS auto_reduce_mps
       ,msib.costing_enabled_flag           AS costing_enabled_flag
       ,msib.auto_created_config_flag       AS auto_created_config_flag
       ,msib.cycle_count_enabled_flag       AS cycle_count_enabled_flag
       ,msib.item_type                      AS item_type
       ,msib.model_config_clause_name       AS model_config_clause_name
       ,msib.ship_model_complete_flag       AS ship_model_complete_flag
       ,msib.mrp_planning_code              AS mrp_planning_code
       ,msib.return_inspection_requirement  AS return_inspection_requirement
       ,msib.ato_forecast_control           AS ato_forecast_control
       ,msib.release_time_fence_code        AS release_time_fence_code
       ,msib.release_time_fence_days        AS release_time_fence_days
       ,msib.container_item_flag            AS container_item_flag
       ,msib.vehicle_item_flag              AS vehicle_item_flag
       ,msib.maximum_load_weight            AS maximum_load_weight
       ,msib.minimum_fill_percent           AS minimum_fill_percent
       ,msib.container_type_code            AS container_type_code
       ,msib.internal_volume                AS internal_volume
       ,msib.wh_update_date                 AS wh_update_date
       ,msib.product_family_item_id         AS product_family_item_id
       ,msib.global_attribute_category      AS global_attribute_category
       ,msib.global_attribute1              AS global_attribute1
       ,msib.global_attribute2              AS global_attribute2
       ,msib.global_attribute3              AS global_attribute3
       ,msib.global_attribute4              AS global_attribute4
       ,msib.global_attribute5              AS global_attribute5
       ,msib.global_attribute6              AS global_attribute6
       ,msib.global_attribute7              AS global_attribute7
       ,msib.global_attribute8              AS global_attribute8
       ,msib.global_attribute9              AS global_attribute9
       ,msib.global_attribute10             AS global_attribute10
       ,msib.purchasing_tax_code            AS purchasing_tax_code
       ,msib.overcompletion_tolerance_type  AS overcompletion_tolerance_type
       ,msib.overcompletion_tolerance_value AS overcompletion_tolerance_value
       ,msib.effectivity_control            AS effectivity_control
       ,msib.check_shortages_flag           AS check_shortages_flag
       ,msib.over_shipment_tolerance        AS over_shipment_tolerance
       ,msib.under_shipment_tolerance       AS under_shipment_tolerance
       ,msib.over_return_tolerance          AS over_return_tolerance
       ,msib.under_return_tolerance         AS under_return_tolerance
       ,msib.equipment_type                 AS equipment_type
       ,msib.recovered_part_disp_code       AS recovered_part_disp_code
       ,msib.defect_tracking_on_flag        AS defect_tracking_on_flag
       ,msib.usage_item_flag                AS usage_item_flag
       ,msib.event_flag                     AS event_flag
       ,msib.electronic_flag                AS electronic_flag
       ,msib.downloadable_flag              AS downloadable_flag
       ,msib.vol_discount_exempt_flag       AS vol_discount_exempt_flag
       ,msib.coupon_exempt_flag             AS coupon_exempt_flag
       ,msib.comms_nl_trackable_flag        AS comms_nl_trackable_flag
       ,msib.asset_creation_code            AS asset_creation_code
       ,msib.comms_activation_reqd_flag     AS comms_activation_reqd_flag
       ,msib.orderable_on_web_flag          AS orderable_on_web_flag
       ,msib.back_orderable_flag            AS back_orderable_flag
       ,msib.web_status                     AS web_status
       ,msib.indivisible_flag               AS indivisible_flag
       ,msib.dimension_uom_code             AS dimension_uom_code
       ,msib.unit_length                    AS unit_length
       ,msib.unit_width                     AS unit_width
       ,msib.unit_height                    AS unit_height
       ,msib.bulk_picked_flag               AS bulk_picked_flag
       ,msib.lot_status_enabled             AS lot_status_enabled
       ,msib.default_lot_status_id          AS default_lot_status_id
       ,msib.serial_status_enabled          AS serial_status_enabled
       ,msib.default_serial_status_id       AS default_serial_status_id
       ,msib.lot_split_enabled              AS lot_split_enabled
       ,msib.lot_merge_enabled              AS lot_merge_enabled
       ,msib.inventory_carry_penalty        AS inventory_carry_penalty
       ,msib.operation_slack_penalty        AS operation_slack_penalty
       ,msib.financing_allowed_flag         AS financing_allowed_flag
       ,msib.eam_item_type                  AS eam_item_type
       ,msib.eam_activity_type_code         AS eam_activity_type_code
       ,msib.eam_activity_cause_code        AS eam_activity_cause_code
       ,msib.eam_act_notification_flag      AS eam_act_notification_flag
       ,msib.eam_act_shutdown_status        AS eam_act_shutdown_status
       ,msib.dual_uom_control               AS dual_uom_control
       ,msib.secondary_uom_code             AS secondary_uom_code
       ,msib.dual_uom_deviation_high        AS dual_uom_deviation_high
       ,msib.dual_uom_deviation_low         AS dual_uom_deviation_low
       ,msib.contract_item_type_code        AS contract_item_type_code
       ,msib.subscription_depend_flag       AS subscription_depend_flag
       ,msib.serv_req_enabled_code          AS serv_req_enabled_code
       ,msib.serv_billing_enabled_flag      AS serv_billing_enabled_flag
       ,msib.serv_importance_level          AS serv_importance_level
       ,msib.planned_inv_point_flag         AS planned_inv_point_flag
       ,msib.lot_translate_enabled          AS lot_translate_enabled
       ,msib.default_so_source_type         AS default_so_source_type
       ,msib.create_supply_flag             AS create_supply_flag
       ,msib.substitution_window_code       AS substitution_window_code
       ,msib.substitution_window_days       AS substitution_window_days
       ,msib.ib_item_instance_class         AS ib_item_instance_class
       ,msib.config_model_type              AS config_model_type
       ,msib.lot_substitution_enabled       AS lot_substitution_enabled
       ,msib.minimum_license_quantity       AS minimum_license_quantity
       ,msib.eam_activity_source_code       AS eam_activity_source_code
       ,msib.lifecycle_id                   AS lifecycle_id
       ,msib.current_phase_id               AS current_phase_id
       ,1                                   AS object_version_number
       ,msib.tracking_quantity_ind          AS tracking_quantity_ind
       ,msib.ont_pricing_qty_source         AS ont_pricing_qty_source
       ,msib.secondary_default_ind          AS secondary_default_ind
       ,msib.option_specific_sourced        AS option_specific_sourced
       ,msib.approval_status                AS approval_status
       ,msib.vmi_minimum_units              AS vmi_minimum_units
       ,msib.vmi_minimum_days               AS vmi_minimum_days
       ,msib.vmi_maximum_units              AS vmi_maximum_units
       ,msib.vmi_maximum_days               AS vmi_maximum_days
       ,msib.vmi_fixed_order_quantity       AS vmi_fixed_order_quantity
       ,msib.so_authorization_flag          AS so_authorization_flag
       ,msib.consigned_flag                 AS consigned_flag
       ,msib.asn_autoexpire_flag            AS asn_autoexpire_flag
       ,msib.vmi_forecast_type              AS vmi_forecast_type
       ,msib.forecast_horizon               AS forecast_horizon
       ,msib.exclude_from_budget_flag       AS exclude_from_budget_flag
       ,msib.days_tgt_inv_supply            AS days_tgt_inv_supply
       ,msib.days_tgt_inv_window            AS days_tgt_inv_window
       ,msib.days_max_inv_supply            AS days_max_inv_supply
       ,msib.days_max_inv_window            AS days_max_inv_window
       ,msib.drp_planned_flag               AS drp_planned_flag
       ,msib.critical_component_flag        AS critical_component_flag
       ,msib.continous_transfer             AS continous_transfer
       ,msib.convergence                    AS convergence
       ,msib.divergence                     AS divergence
       ,msib.config_orgs                    AS config_orgs
       ,msib.config_match                   AS config_match
       ,msib.global_attribute11             AS global_attribute11
       ,msib.global_attribute12             AS global_attribute12
       ,msib.global_attribute13             AS global_attribute13
       ,msib.global_attribute14             AS global_attribute14
       ,msib.global_attribute15             AS global_attribute15
       ,msib.global_attribute16             AS global_attribute16
       ,msib.global_attribute17             AS global_attribute17
       ,msib.global_attribute18             AS global_attribute18
       ,msib.global_attribute19             AS global_attribute19
       ,msib.global_attribute20             AS global_attribute20
      FROM
        (SELECT m.*
         FROM   mtl_system_items_b@t4_hon m
         WHERE  m.organization_id = gt_org_id_hon
        )                          msib
       ,mtl_parameters@t4_hon      mp
      WHERE msib.organization_id = mp.organization_id
      MINUS
        SELECT
          NULL                                AS inventory_item_id
         ,NULL                                AS organization_id
         ,mp.organization_code                AS organization_code
         -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
         ,cd_last_update_date                 AS last_update_date
         ,cn_last_updated_by                  AS last_updated_by
         ,cd_creation_date                    AS creation_date
         ,cn_created_by                       AS created_by
         ,cn_last_update_login                AS last_update_login
         --
         ,msib.summary_flag                   AS summary_flag
         ,msib.enabled_flag                   AS enabled_flag
         ,msib.start_date_active              AS start_date_active
         ,msib.end_date_active                AS end_date_active
         ,msib.description                    AS description
         ,msib.buyer_id                       AS buyer_id
         ,msib.accounting_rule_id             AS accounting_rule_id
         ,msib.invoicing_rule_id              AS invoicing_rule_id
         ,msib.segment1                       AS segment1
         ,msib.segment2                       AS segment2
         ,msib.segment3                       AS segment3
         ,msib.segment4                       AS segment4
         ,msib.segment5                       AS segment5
         ,msib.segment6                       AS segment6
         ,msib.segment7                       AS segment7
         ,msib.segment8                       AS segment8
         ,msib.segment9                       AS segment9
         ,msib.segment10                      AS segment10
         ,msib.segment11                      AS segment11
         ,msib.segment12                      AS segment12
         ,msib.segment13                      AS segment13
         ,msib.segment14                      AS segment14
         ,msib.segment15                      AS segment15
         ,msib.segment16                      AS segment16
         ,msib.segment17                      AS segment17
         ,msib.segment18                      AS segment18
         ,msib.segment19                      AS segment19
         ,msib.segment20                      AS segment20
         ,msib.attribute_category             AS attribute_category
         ,msib.attribute1                     AS attribute1
         ,msib.attribute2                     AS attribute2
         ,msib.attribute3                     AS attribute3
         ,msib.attribute4                     AS attribute4
         ,msib.attribute5                     AS attribute5
         ,msib.attribute6                     AS attribute6
         ,msib.attribute7                     AS attribute7
         ,msib.attribute8                     AS attribute8
         ,msib.attribute9                     AS attribute9
         ,msib.attribute10                    AS attribute10
         ,msib.attribute11                    AS attribute11
         ,msib.attribute12                    AS attribute12
         ,msib.attribute13                    AS attribute13
         ,msib.attribute14                    AS attribute14
         ,msib.attribute15                    AS attribute15
         ,msib.purchasing_item_flag           AS purchasing_item_flag
         ,msib.shippable_item_flag            AS shippable_item_flag
         ,msib.customer_order_flag            AS customer_order_flag
         ,msib.internal_order_flag            AS internal_order_flag
         ,msib.service_item_flag              AS service_item_flag
         ,msib.inventory_item_flag            AS inventory_item_flag
         ,msib.eng_item_flag                  AS eng_item_flag
         ,msib.inventory_asset_flag           AS inventory_asset_flag
         ,msib.purchasing_enabled_flag        AS purchasing_enabled_flag
         ,msib.customer_order_enabled_flag    AS customer_order_enabled_flag
         ,msib.internal_order_enabled_flag    AS internal_order_enabled_flag
         ,msib.so_transactions_flag           AS so_transactions_flag
         ,msib.mtl_transactions_enabled_flag  AS mtl_transactions_enabled_flag
         ,msib.stock_enabled_flag             AS stock_enabled_flag
         ,msib.bom_enabled_flag               AS bom_enabled_flag
         ,msib.build_in_wip_flag              AS build_in_wip_flag
         ,msib.revision_qty_control_code      AS revision_qty_control_code
         ,msib.item_catalog_group_id          AS item_catalog_group_id
         ,msib.catalog_status_flag            AS catalog_status_flag
         ,msib.returnable_flag                AS returnable_flag
         ,msib.default_shipping_org           AS default_shipping_org
         ,msib.collateral_flag                AS collateral_flag
         ,msib.taxable_flag                   AS taxable_flag
         ,msib.qty_rcv_exception_code         AS qty_rcv_exception_code
         ,msib.allow_item_desc_update_flag    AS allow_item_desc_update_flag
         ,msib.inspection_required_flag       AS inspection_required_flag
         ,msib.receipt_required_flag          AS receipt_required_flag
         ,msib.market_price                   AS market_price
         ,msib.hazard_class_id                AS hazard_class_id
         ,msib.rfq_required_flag              AS rfq_required_flag
         ,msib.qty_rcv_tolerance              AS qty_rcv_tolerance
         ,msib.list_price_per_unit            AS list_price_per_unit
         ,msib.un_number_id                   AS un_number_id
         ,msib.price_tolerance_percent        AS price_tolerance_percent
         ,msib.asset_category_id              AS asset_category_id
         ,msib.rounding_factor                AS rounding_factor
         ,msib.unit_of_issue                  AS unit_of_issue
         ,msib.enforce_ship_to_location_code  AS enforce_ship_to_location_code
         ,msib.allow_substitute_receipts_flag AS allow_substitute_receipts_flag
         ,msib.allow_unordered_receipts_flag  AS allow_unordered_receipts_flag
         ,msib.allow_express_delivery_flag    AS allow_express_delivery_flag
         ,msib.days_early_receipt_allowed     AS days_early_receipt_allowed
         ,msib.days_late_receipt_allowed      AS days_late_receipt_allowed
         ,msib.receipt_days_exception_code    AS receipt_days_exception_code
         ,msib.receiving_routing_id           AS receiving_routing_id
         ,msib.invoice_close_tolerance        AS invoice_close_tolerance
         ,msib.receive_close_tolerance        AS receive_close_tolerance
         ,msib.auto_lot_alpha_prefix          AS auto_lot_alpha_prefix
         ,msib.start_auto_lot_number          AS start_auto_lot_number
         ,msib.lot_control_code               AS lot_control_code
         ,msib.shelf_life_code                AS shelf_life_code
         ,msib.shelf_life_days                AS shelf_life_days
         ,msib.serial_number_control_code     AS serial_number_control_code
         ,msib.start_auto_serial_number       AS start_auto_serial_number
         ,msib.auto_serial_alpha_prefix       AS auto_serial_alpha_prefix
         ,msib.source_type                    AS source_type
         ,msib.source_organization_id         AS source_organization_id
         ,msib.source_subinventory            AS source_subinventory
         ,msib.expense_account                AS expense_account
         ,msib.encumbrance_account            AS encumbrance_account
         ,msib.restrict_subinventories_code   AS restrict_subinventories_code
         ,msib.unit_weight                    AS unit_weight
         ,msib.weight_uom_code                AS weight_uom_code
         ,msib.volume_uom_code                AS volume_uom_code
         ,msib.unit_volume                    AS unit_volume
         ,msib.restrict_locators_code         AS restrict_locators_code
         ,msib.location_control_code          AS location_control_code
         ,msib.shrinkage_rate                 AS shrinkage_rate
         ,msib.acceptable_early_days          AS acceptable_early_days
         ,msib.planning_time_fence_code       AS planning_time_fence_code
         ,msib.demand_time_fence_code         AS demand_time_fence_code
         ,msib.lead_time_lot_size             AS lead_time_lot_size
         ,msib.std_lot_size                   AS std_lot_size
         ,msib.cum_manufacturing_lead_time    AS cum_manufacturing_lead_time
         ,msib.overrun_percentage             AS overrun_percentage
         ,msib.mrp_calculate_atp_flag         AS mrp_calculate_atp_flag
         ,msib.acceptable_rate_increase       AS acceptable_rate_increase
         ,msib.acceptable_rate_decrease       AS acceptable_rate_decrease
         ,msib.cumulative_total_lead_time     AS cumulative_total_lead_time
         ,msib.planning_time_fence_days       AS planning_time_fence_days
         ,msib.demand_time_fence_days         AS demand_time_fence_days
         ,msib.end_assembly_pegging_flag      AS end_assembly_pegging_flag
         ,msib.repetitive_planning_flag       AS repetitive_planning_flag
         ,msib.planning_exception_set         AS planning_exception_set
         ,msib.bom_item_type                  AS bom_item_type
         ,msib.pick_components_flag           AS pick_components_flag
         ,msib.replenish_to_order_flag        AS replenish_to_order_flag
         ,msib.base_item_id                   AS base_item_id
         ,msib.atp_components_flag            AS atp_components_flag
         ,msib.atp_flag                       AS atp_flag
         ,msib.fixed_lead_time                AS fixed_lead_time
         ,msib.variable_lead_time             AS variable_lead_time
         ,msib.wip_supply_locator_id          AS wip_supply_locator_id
         ,msib.wip_supply_type                AS wip_supply_type
         ,msib.wip_supply_subinventory        AS wip_supply_subinventory
         ,msib.primary_uom_code               AS primary_uom_code
         ,msib.primary_unit_of_measure        AS primary_unit_of_measure
         ,msib.allowed_units_lookup_code      AS allowed_units_lookup_code
         ,1                                   AS cost_of_sales_account
         ,1                                   AS sales_account
         ,msib.default_include_in_rollup_flag AS default_include_in_rollup_flag
         ,msib.inventory_item_status_code     AS inventory_item_status_code
         ,msib.inventory_planning_code        AS inventory_planning_code
         ,msib.planner_code                   AS planner_code
         ,msib.planning_make_buy_code         AS planning_make_buy_code
         ,msib.fixed_lot_multiplier           AS fixed_lot_multiplier
         ,msib.rounding_control_type          AS rounding_control_type
         ,msib.carrying_cost                  AS carrying_cost
         ,msib.postprocessing_lead_time       AS postprocessing_lead_time
         ,msib.preprocessing_lead_time        AS preprocessing_lead_time
         ,msib.full_lead_time                 AS full_lead_time
         ,msib.order_cost                     AS order_cost
         ,msib.mrp_safety_stock_percent       AS mrp_safety_stock_percent
         ,msib.mrp_safety_stock_code          AS mrp_safety_stock_code
         ,msib.min_minmax_quantity            AS min_minmax_quantity
         ,msib.max_minmax_quantity            AS max_minmax_quantity
         ,msib.minimum_order_quantity         AS minimum_order_quantity
         ,msib.fixed_order_quantity           AS fixed_order_quantity
         ,msib.fixed_days_supply              AS fixed_days_supply
         ,msib.maximum_order_quantity         AS maximum_order_quantity
         ,msib.atp_rule_id                    AS atp_rule_id
         ,msib.picking_rule_id                AS picking_rule_id
         ,NULL                                AS reservable_type
         ,msib.positive_measurement_error     AS positive_measurement_error
         ,msib.negative_measurement_error     AS negative_measurement_error
         ,msib.engineering_ecn_code           AS engineering_ecn_code
         ,msib.engineering_item_id            AS engineering_item_id
         ,msib.engineering_date               AS engineering_date
         ,msib.service_starting_delay         AS service_starting_delay
         ,msib.vendor_warranty_flag           AS vendor_warranty_flag
         ,msib.serviceable_component_flag     AS serviceable_component_flag
         ,msib.serviceable_product_flag       AS serviceable_product_flag
         ,msib.base_warranty_service_id       AS base_warranty_service_id
         ,msib.payment_terms_id               AS payment_terms_id
         ,msib.preventive_maintenance_flag    AS preventive_maintenance_flag
         ,msib.primary_specialist_id          AS primary_specialist_id
         ,msib.secondary_specialist_id        AS secondary_specialist_id
         ,msib.serviceable_item_class_id      AS serviceable_item_class_id
         ,msib.time_billable_flag             AS time_billable_flag
         ,msib.material_billable_flag         AS material_billable_flag
         ,msib.expense_billable_flag          AS expense_billable_flag
         ,msib.prorate_service_flag           AS prorate_service_flag
         ,msib.coverage_schedule_id           AS coverage_schedule_id
         ,msib.service_duration_period_code   AS service_duration_period_code
         ,msib.service_duration               AS service_duration
         ,msib.warranty_vendor_id             AS warranty_vendor_id
         ,msib.max_warranty_amount            AS max_warranty_amount
         ,msib.response_time_period_code      AS response_time_period_code
         ,msib.response_time_value            AS response_time_value
         ,msib.new_revision_code              AS new_revision_code
         ,msib.invoiceable_item_flag          AS invoiceable_item_flag
         ,msib.tax_code                       AS tax_code
         ,msib.invoice_enabled_flag           AS invoice_enabled_flag
         ,msib.must_use_approved_vendor_flag  AS must_use_approved_vendor_flag
         -- OPM�i�ڃg���K�[�N���R���J�����g�ōX�V����邽�ߍ����ΏۊO
         ,cn_request_id                       AS request_id
         ,cn_program_application_id           AS program_application_id
         ,cn_program_id                       AS program_id
         ,cd_program_update_date              AS program_update_date
         --
         ,msib.outside_operation_flag         AS outside_operation_flag
         ,msib.outside_operation_uom_type     AS outside_operation_uom_type
         ,msib.safety_stock_bucket_days       AS safety_stock_bucket_days
         ,msib.auto_reduce_mps                AS auto_reduce_mps
         ,msib.costing_enabled_flag           AS costing_enabled_flag
         ,msib.auto_created_config_flag       AS auto_created_config_flag
         ,msib.cycle_count_enabled_flag       AS cycle_count_enabled_flag
         ,msib.item_type                      AS item_type
         ,msib.model_config_clause_name       AS model_config_clause_name
         ,msib.ship_model_complete_flag       AS ship_model_complete_flag
         ,msib.mrp_planning_code              AS mrp_planning_code
         ,msib.return_inspection_requirement  AS return_inspection_requirement
         ,msib.ato_forecast_control           AS ato_forecast_control
         ,msib.release_time_fence_code        AS release_time_fence_code
         ,msib.release_time_fence_days        AS release_time_fence_days
         ,msib.container_item_flag            AS container_item_flag
         ,msib.vehicle_item_flag              AS vehicle_item_flag
         ,msib.maximum_load_weight            AS maximum_load_weight
         ,msib.minimum_fill_percent           AS minimum_fill_percent
         ,msib.container_type_code            AS container_type_code
         ,msib.internal_volume                AS internal_volume
         ,msib.wh_update_date                 AS wh_update_date
         ,msib.product_family_item_id         AS product_family_item_id
         ,msib.global_attribute_category      AS global_attribute_category
         ,msib.global_attribute1              AS global_attribute1
         ,msib.global_attribute2              AS global_attribute2
         ,msib.global_attribute3              AS global_attribute3
         ,msib.global_attribute4              AS global_attribute4
         ,msib.global_attribute5              AS global_attribute5
         ,msib.global_attribute6              AS global_attribute6
         ,msib.global_attribute7              AS global_attribute7
         ,msib.global_attribute8              AS global_attribute8
         ,msib.global_attribute9              AS global_attribute9
         ,msib.global_attribute10             AS global_attribute10
         ,msib.purchasing_tax_code            AS purchasing_tax_code
         ,msib.overcompletion_tolerance_type  AS overcompletion_tolerance_type
         ,msib.overcompletion_tolerance_value AS overcompletion_tolerance_value
         ,msib.effectivity_control            AS effectivity_control
         ,msib.check_shortages_flag           AS check_shortages_flag
         ,msib.over_shipment_tolerance        AS over_shipment_tolerance
         ,msib.under_shipment_tolerance       AS under_shipment_tolerance
         ,msib.over_return_tolerance          AS over_return_tolerance
         ,msib.under_return_tolerance         AS under_return_tolerance
         ,msib.equipment_type                 AS equipment_type
         ,msib.recovered_part_disp_code       AS recovered_part_disp_code
         ,msib.defect_tracking_on_flag        AS defect_tracking_on_flag
         ,msib.usage_item_flag                AS usage_item_flag
         ,msib.event_flag                     AS event_flag
         ,msib.electronic_flag                AS electronic_flag
         ,msib.downloadable_flag              AS downloadable_flag
         ,msib.vol_discount_exempt_flag       AS vol_discount_exempt_flag
         ,msib.coupon_exempt_flag             AS coupon_exempt_flag
         ,msib.comms_nl_trackable_flag        AS comms_nl_trackable_flag
         ,msib.asset_creation_code            AS asset_creation_code
         ,msib.comms_activation_reqd_flag     AS comms_activation_reqd_flag
         ,msib.orderable_on_web_flag          AS orderable_on_web_flag
         ,msib.back_orderable_flag            AS back_orderable_flag
         ,msib.web_status                     AS web_status
         ,msib.indivisible_flag               AS indivisible_flag
         ,msib.dimension_uom_code             AS dimension_uom_code
         ,msib.unit_length                    AS unit_length
         ,msib.unit_width                     AS unit_width
         ,msib.unit_height                    AS unit_height
         ,msib.bulk_picked_flag               AS bulk_picked_flag
         ,msib.lot_status_enabled             AS lot_status_enabled
         ,msib.default_lot_status_id          AS default_lot_status_id
         ,msib.serial_status_enabled          AS serial_status_enabled
         ,msib.default_serial_status_id       AS default_serial_status_id
         ,msib.lot_split_enabled              AS lot_split_enabled
         ,msib.lot_merge_enabled              AS lot_merge_enabled
         ,msib.inventory_carry_penalty        AS inventory_carry_penalty
         ,msib.operation_slack_penalty        AS operation_slack_penalty
         ,msib.financing_allowed_flag         AS financing_allowed_flag
         ,msib.eam_item_type                  AS eam_item_type
         ,msib.eam_activity_type_code         AS eam_activity_type_code
         ,msib.eam_activity_cause_code        AS eam_activity_cause_code
         ,msib.eam_act_notification_flag      AS eam_act_notification_flag
         ,msib.eam_act_shutdown_status        AS eam_act_shutdown_status
         ,msib.dual_uom_control               AS dual_uom_control
         ,msib.secondary_uom_code             AS secondary_uom_code
         ,msib.dual_uom_deviation_high        AS dual_uom_deviation_high
         ,msib.dual_uom_deviation_low         AS dual_uom_deviation_low
         ,msib.contract_item_type_code        AS contract_item_type_code
         ,msib.subscription_depend_flag       AS subscription_depend_flag
         ,msib.serv_req_enabled_code          AS serv_req_enabled_code
         ,msib.serv_billing_enabled_flag      AS serv_billing_enabled_flag
         ,msib.serv_importance_level          AS serv_importance_level
         ,msib.planned_inv_point_flag         AS planned_inv_point_flag
         ,msib.lot_translate_enabled          AS lot_translate_enabled
         ,msib.default_so_source_type         AS default_so_source_type
         ,msib.create_supply_flag             AS create_supply_flag
         ,msib.substitution_window_code       AS substitution_window_code
         ,msib.substitution_window_days       AS substitution_window_days
         ,msib.ib_item_instance_class         AS ib_item_instance_class
         ,msib.config_model_type              AS config_model_type
         ,msib.lot_substitution_enabled       AS lot_substitution_enabled
         ,msib.minimum_license_quantity       AS minimum_license_quantity
         ,msib.eam_activity_source_code       AS eam_activity_source_code
         ,msib.lifecycle_id                   AS lifecycle_id
         ,msib.current_phase_id               AS current_phase_id
         ,1                                   AS object_version_number
         ,msib.tracking_quantity_ind          AS tracking_quantity_ind
         ,msib.ont_pricing_qty_source         AS ont_pricing_qty_source
         ,msib.secondary_default_ind          AS secondary_default_ind
         ,msib.option_specific_sourced        AS option_specific_sourced
         ,msib.approval_status                AS approval_status
         ,msib.vmi_minimum_units              AS vmi_minimum_units
         ,msib.vmi_minimum_days               AS vmi_minimum_days
         ,msib.vmi_maximum_units              AS vmi_maximum_units
         ,msib.vmi_maximum_days               AS vmi_maximum_days
         ,msib.vmi_fixed_order_quantity       AS vmi_fixed_order_quantity
         ,msib.so_authorization_flag          AS so_authorization_flag
         ,msib.consigned_flag                 AS consigned_flag
         ,msib.asn_autoexpire_flag            AS asn_autoexpire_flag
         ,msib.vmi_forecast_type              AS vmi_forecast_type
         ,msib.forecast_horizon               AS forecast_horizon
         ,msib.exclude_from_budget_flag       AS exclude_from_budget_flag
         ,msib.days_tgt_inv_supply            AS days_tgt_inv_supply
         ,msib.days_tgt_inv_window            AS days_tgt_inv_window
         ,msib.days_max_inv_supply            AS days_max_inv_supply
         ,msib.days_max_inv_window            AS days_max_inv_window
         ,msib.drp_planned_flag               AS drp_planned_flag
         ,msib.critical_component_flag        AS critical_component_flag
         ,msib.continous_transfer             AS continous_transfer
         ,msib.convergence                    AS convergence
         ,msib.divergence                     AS divergence
         ,msib.config_orgs                    AS config_orgs
         ,msib.config_match                   AS config_match
         ,msib.global_attribute11             AS global_attribute11
         ,msib.global_attribute12             AS global_attribute12
         ,msib.global_attribute13             AS global_attribute13
         ,msib.global_attribute14             AS global_attribute14
         ,msib.global_attribute15             AS global_attribute15
         ,msib.global_attribute16             AS global_attribute16
         ,msib.global_attribute17             AS global_attribute17
         ,msib.global_attribute18             AS global_attribute18
         ,msib.global_attribute19             AS global_attribute19
         ,msib.global_attribute20             AS global_attribute20
        FROM
          (SELECT m.*
           FROM   mtl_system_items_b m
           WHERE  m.organization_id = gt_org_id_t4
          )                   msib
         ,mtl_parameters      mp
        WHERE msib.organization_id = mp.organization_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   (SELECT m.*
              FROM   mtl_system_items_b m
              WHERE  m.organization_id = gt_org_id_t4
             )                  b
            ,mtl_parameters     b2
      WHERE  b.organization_id    = b2.organization_id
        AND  b.segment1           = a.segment1
        AND  b2.organization_code = a.organization_code
    )
  ;
  TYPE get_msib_ttype IS TABLE OF xxccp_mtl_system_items_b%ROWTYPE INDEX BY BINARY_INTEGER;
  get_msib_tab get_msib_ttype;
--
  -- DISC�i�ڃA�h�I���}�X�^�������oSQL
  CURSOR get_xsib_cur
  IS
    --�ǉ�
    SELECT
      a.item_id                    AS item_id
     ,a.item_code                  AS item_code
     ,a.tax_rate                   AS tax_rate
     ,a.baracha_div                AS baracha_div
     ,a.nets                       AS nets
     ,a.nets_uom_code              AS nets_uom_code
     ,a.inc_num                    AS inc_num
     ,a.vessel_group               AS vessel_group
     ,a.acnt_group                 AS acnt_group
     ,a.acnt_vessel_group          AS acnt_vessel_group
     ,a.brand_group                AS brand_group
     ,a.sp_supplier_code           AS sp_supplier_code
     ,a.case_jan_code              AS case_jan_code
     ,a.new_item_div               AS new_item_div
     ,a.bowl_inc_num               AS bowl_inc_num
     ,a.item_status_apply_date     AS item_status_apply_date
     ,a.item_status                AS item_status
     ,a.renewal_item_code          AS renewal_item_code
     ,a.search_update_date         AS search_update_date
     ,a.case_conv_inc_num          AS case_conv_inc_num
     ,a.created_by                 AS created_by
     ,a.creation_date              AS creation_date
     ,a.last_updated_by            AS last_updated_by
     ,a.last_update_date           AS last_update_date
     ,a.last_update_login          AS last_update_login
     ,a.request_id                 AS request_id
     ,a.program_application_id     AS program_application_id
     ,a.program_id                 AS program_id
     ,a.program_update_date        AS program_update_date
     ,'I'                          AS record_type
    FROM
      xxcmm_system_items_b@t4_hon  a
    WHERE NOT EXISTS(
      SELECT 1
      FROM   xxcmm_system_items_b b
      WHERE  b.item_code = a.item_code
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.item_id                    AS item_id
     ,a.item_code                  AS item_code
     ,a.tax_rate                   AS tax_rate
     ,a.baracha_div                AS baracha_div
     ,a.nets                       AS nets
     ,a.nets_uom_code              AS nets_uom_code
     ,a.inc_num                    AS inc_num
     ,a.vessel_group               AS vessel_group
     ,a.acnt_group                 AS acnt_group
     ,a.acnt_vessel_group          AS acnt_vessel_group
     ,a.brand_group                AS brand_group
     ,a.sp_supplier_code           AS sp_supplier_code
     ,a.case_jan_code              AS case_jan_code
     ,a.new_item_div               AS new_item_div
     ,a.bowl_inc_num               AS bowl_inc_num
     ,a.item_status_apply_date     AS item_status_apply_date
     ,a.item_status                AS item_status
     ,a.renewal_item_code          AS renewal_item_code
     ,a.search_update_date         AS search_update_date
     ,a.case_conv_inc_num          AS case_conv_inc_num
     ,a.created_by                 AS created_by
     ,a.creation_date              AS creation_date
     ,a.last_updated_by            AS last_updated_by
     ,a.last_update_date           AS last_update_date
     ,a.last_update_login          AS last_update_login
     ,a.request_id                 AS request_id
     ,a.program_application_id     AS program_application_id
     ,a.program_id                 AS program_id
     ,a.program_update_date        AS program_update_date
     ,'U'                          AS record_type
    FROM(
      SELECT
        NULL                         AS item_id
       ,xsib.item_code               AS item_code
       ,xsib.tax_rate                AS tax_rate
       ,xsib.baracha_div             AS baracha_div
       ,xsib.nets                    AS nets
       ,xsib.nets_uom_code           AS nets_uom_code
       ,xsib.inc_num                 AS inc_num
       ,xsib.vessel_group            AS vessel_group
       ,xsib.acnt_group              AS acnt_group
       ,xsib.acnt_vessel_group       AS acnt_vessel_group
       ,xsib.brand_group             AS brand_group
       ,xsib.sp_supplier_code        AS sp_supplier_code
       ,xsib.case_jan_code           AS case_jan_code
       ,xsib.new_item_div            AS new_item_div
       ,xsib.bowl_inc_num            AS bowl_inc_num
       ,xsib.item_status_apply_date  AS item_status_apply_date
       ,xsib.item_status             AS item_status
       ,xsib.renewal_item_code       AS renewal_item_code
       ,xsib.search_update_date      AS search_update_date
       ,xsib.case_conv_inc_num       AS case_conv_inc_num
       ,xsib.created_by              AS created_by
       ,xsib.creation_date           AS creation_date
       ,xsib.last_updated_by         AS last_updated_by
       ,xsib.last_update_date        AS last_update_date
       ,xsib.last_update_login       AS last_update_login
       ,xsib.request_id              AS request_id
       ,xsib.program_application_id  AS program_application_id
       ,xsib.program_id              AS program_id
       ,xsib.program_update_date     AS program_update_date
      FROM
        xxcmm_system_items_b@t4_hon  xsib
      MINUS
        SELECT
          NULL                         AS item_id
         ,xsib.item_code               AS item_code
         ,xsib.tax_rate                AS tax_rate
         ,xsib.baracha_div             AS baracha_div
         ,xsib.nets                    AS nets
         ,xsib.nets_uom_code           AS nets_uom_code
         ,xsib.inc_num                 AS inc_num
         ,xsib.vessel_group            AS vessel_group
         ,xsib.acnt_group              AS acnt_group
         ,xsib.acnt_vessel_group       AS acnt_vessel_group
         ,xsib.brand_group             AS brand_group
         ,xsib.sp_supplier_code        AS sp_supplier_code
         ,xsib.case_jan_code           AS case_jan_code
         ,xsib.new_item_div            AS new_item_div
         ,xsib.bowl_inc_num            AS bowl_inc_num
         ,xsib.item_status_apply_date  AS item_status_apply_date
         ,xsib.item_status             AS item_status
         ,xsib.renewal_item_code       AS renewal_item_code
         ,xsib.search_update_date      AS search_update_date
         ,xsib.case_conv_inc_num       AS case_conv_inc_num
         ,xsib.created_by              AS created_by
         ,xsib.creation_date           AS creation_date
         ,xsib.last_updated_by         AS last_updated_by
         ,xsib.last_update_date        AS last_update_date
         ,xsib.last_update_login       AS last_update_login
         ,xsib.request_id              AS request_id
         ,xsib.program_application_id  AS program_application_id
         ,xsib.program_id              AS program_id
         ,xsib.program_update_date     AS program_update_date
        FROM
          xxcmm_system_items_b  xsib
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM xxcmm_system_items_b  b
      WHERE a.item_code = b.item_code
    )
  ;
  TYPE get_xsib_ttype IS TABLE OF xxccp_xcmm_system_items_b%ROWTYPE INDEX BY BINARY_INTEGER;
  get_xsib_tab get_xsib_ttype;
--
  -- DISC�i�ڃJ�e�S�������������oSQL
  CURSOR get_mic_cur
  IS
    --�ǉ�
    SELECT
      mic.inventory_item_id       AS inventory_item_id
     ,msib.segment1               AS item_no
     ,mic.organization_id         AS organization_id
     ,mp.organization_code        AS organization_code
     ,mic.category_set_id         AS category_set_id
     ,mcsv.category_set_name      AS category_set_name
     ,mic.category_id             AS category_id
     ,mcv.segment1                AS segment1
     ,cd_last_update_date         AS last_update_date
     ,cn_last_updated_by          AS last_updated_by
     ,cd_creation_date            AS creation_date
     ,cn_created_by               AS created_by
     ,cn_last_update_login        AS last_update_login
     ,cn_request_id               AS request_id
     ,cn_program_application_id   AS program_application_id
     ,cn_program_id               AS program_id
     ,cd_program_update_date      AS program_update_date
     ,'I'                         AS record_type
    FROM
      (SELECT m.*
       FROM   mtl_item_categories@t4_hon m
       WHERE  m.organization_id = gt_mst_org_id_hon
      )                           mic
     ,mtl_category_sets_vl@t4_hon mcsv
     ,mtl_categories_vl@t4_hon    mcv
     ,mtl_system_items_b@t4_hon   msib
     ,mtl_parameters@t4_hon       mp
    WHERE mic.category_set_id    = mcsv.category_set_id
      AND mic.category_id        = mcv.category_id
      AND mic.inventory_item_id  = msib.inventory_item_id
      AND mic.organization_id    = msib.organization_id
      AND msib.organization_id   = mp.organization_id
      AND NOT EXISTS(
        SELECT 1
        FROM   (SELECT m2.*
                FROM   mtl_item_categories m2
                WHERE  m2.organization_id = gt_mst_org_id_t4
               )                    mic2
              ,mtl_category_sets_vl mcsv2
              ,mtl_categories_vl    mcv2
              ,mtl_system_items_b   msib2
              ,mtl_parameters       mp2
        WHERE mic2.category_set_id    = mcsv2.category_set_id
          AND mic2.category_id        = mcv2.category_id
          AND mic2.inventory_item_id  = msib2.inventory_item_id
          AND mic2.organization_id    = msib2.organization_id
          AND msib2.organization_id   = mp2.organization_id
          AND msib2.segment1          = msib.segment1
          AND mp2.organization_code   = mp.organization_code
          AND mcsv2.category_set_name = mcsv.category_set_name
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.inventory_item_id       AS inventory_item_id
     ,a.item_no                 AS item_no
     ,a.organization_id         AS organization_id
     ,a.organization_code       AS organization_code
     ,a.category_set_id         AS category_set_id
     ,a.category_set_name       AS category_set_name
     ,a.category_id             AS category_id
     ,a.segment1                AS segment1
     ,a.last_update_date        AS last_update_date
     ,a.last_updated_by         AS last_updated_by
     ,a.creation_date           AS creation_date
     ,a.created_by              AS created_by
     ,a.last_update_login       AS last_update_login
     ,a.request_id              AS request_id
     ,a.program_application_id  AS program_application_id
     ,a.program_id              AS program_id
     ,a.program_update_date     AS program_update_date
     ,'U'                       AS record_type
    FROM(
      SELECT
        NULL                        AS inventory_item_id
       ,msib.segment1               AS item_no
       ,NULL                        AS organization_id
       ,mp.organization_code        AS organization_code
       ,NULL                        AS category_set_id
       ,mcsv.category_set_name      AS category_set_name
       ,NULL                        AS category_id
       ,mcv.segment1                AS segment1
       ,cd_last_update_date         AS last_update_date
       ,cn_last_updated_by          AS last_updated_by
       ,cd_creation_date            AS creation_date
       ,cn_created_by               AS created_by
       ,cn_last_update_login        AS last_update_login
       ,cn_request_id               AS request_id
       ,cn_program_application_id   AS program_application_id
       ,cn_program_id               AS program_id
       ,cd_program_update_date      AS program_update_date
    FROM
        (SELECT m.*
         FROM   mtl_item_categories@t4_hon m
         WHERE  m.organization_id = gt_mst_org_id_hon
        )                           mic
       ,mtl_category_sets_vl@t4_hon mcsv
       ,mtl_categories_vl@t4_hon    mcv
       ,mtl_system_items_b@t4_hon   msib
       ,mtl_parameters@t4_hon       mp
      WHERE mic.category_set_id    = mcsv.category_set_id
        AND mic.category_id        = mcv.category_id
        AND mic.inventory_item_id  = msib.inventory_item_id
        AND mic.organization_id    = msib.organization_id
        AND msib.organization_id   = mp.organization_id
      MINUS
        SELECT
          NULL                        AS inventory_item_id
         ,msib2.segment1              AS item_no
         ,NULL                        AS organization_id
         ,mp2.organization_code       AS organization_code
         ,NULL                        AS category_set_id
         ,mcsv2.category_set_name     AS category_set_name
         ,NULL                        AS category_id
         ,mcv2.segment1               AS segment1
         ,cd_last_update_date         AS last_update_date
         ,cn_last_updated_by          AS last_updated_by
         ,cd_creation_date            AS creation_date
         ,cn_created_by               AS created_by
         ,cn_last_update_login        AS last_update_login
         ,cn_request_id               AS request_id
         ,cn_program_application_id   AS program_application_id
         ,cn_program_id               AS program_id
         ,cd_program_update_date      AS program_update_date
        FROM
          (SELECT m2.*
           FROM   mtl_item_categories m2
           WHERE  m2.organization_id = gt_mst_org_id_t4
          )                           mic2
         ,mtl_category_sets_vl mcsv2
         ,mtl_categories_vl    mcv2
         ,mtl_system_items_b   msib2
         ,mtl_parameters       mp2
        WHERE mic2.category_set_id    = mcsv2.category_set_id
          AND mic2.category_id        = mcv2.category_id
          AND mic2.inventory_item_id  = msib2.inventory_item_id
          AND mic2.organization_id    = msib2.organization_id
          AND msib2.organization_id   = mp2.organization_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   (SELECT m3.*
              FROM   mtl_item_categories m3
              WHERE  m3.organization_id = gt_mst_org_id_t4
             )                    mic3
            ,mtl_category_sets_vl mcsv3
            ,mtl_categories_vl    mcv3
            ,mtl_system_items_b   msib3
            ,mtl_parameters       mp3
      WHERE mic3.category_set_id    = mcsv3.category_set_id
        AND mic3.category_id        = mcv3.category_id
        AND mic3.inventory_item_id  = msib3.inventory_item_id
        AND mic3.organization_id    = msib3.organization_id
        AND msib3.organization_id   = mp3.organization_id
        AND a.item_no               = msib3.segment1
        AND a.organization_code     = mp3.organization_code
        AND a.category_set_name     = mcsv3.category_set_name
    )
  ;
  TYPE get_mic_ttype IS TABLE OF xxccp_mtl_item_categories%ROWTYPE INDEX BY BINARY_INTEGER;
  get_mic_tab get_mic_ttype;
--
  -- DISC�i�ڕύX�����A�h�I���������oSQL
  CURSOR get_xsibh_cur
  IS
    --�ǉ�
    SELECT
      a.item_hst_id             AS item_hst_id
     ,a.item_id                 AS item_id
     ,a.item_code               AS item_code
     ,a.apply_date              AS apply_date
     ,a.apply_flag              AS apply_flag
     ,a.item_status             AS item_status
     ,a.policy_group            AS policy_group
     ,a.fixed_price             AS fixed_price
     ,a.discrete_cost           AS discrete_cost
     ,a.first_apply_flag        AS first_apply_flag
     ,a.created_by              AS created_by
     ,a.creation_date           AS creation_date
     ,a.last_updated_by         AS last_updated_by
     ,a.last_update_date        AS last_update_date
     ,a.last_update_login       AS last_update_login
     ,a.request_id              AS request_id
     ,a.program_application_id  AS program_application_id
     ,a.program_id              AS program_id
     ,a.program_update_date     AS program_update_date
     ,'I'                       AS record_type
    FROM
      xxcmm_system_items_b_hst@t4_hon  a
    WHERE NOT EXISTS(
      SELECT 1
      FROM   xxcmm_system_items_b_hst b
      WHERE  b.item_hst_id = a.item_hst_id
    )
--
    UNION ALL
--
    --�폜
    SELECT
      a.item_hst_id             AS item_hst_id
     ,a.item_id                 AS item_id
     ,a.item_code               AS item_code
     ,a.apply_date              AS apply_date
     ,a.apply_flag              AS apply_flag
     ,a.item_status             AS item_status
     ,a.policy_group            AS policy_group
     ,a.fixed_price             AS fixed_price
     ,a.discrete_cost           AS discrete_cost
     ,a.first_apply_flag        AS first_apply_flag
     ,a.created_by              AS created_by
     ,a.creation_date           AS creation_date
     ,a.last_updated_by         AS last_updated_by
     ,a.last_update_date        AS last_update_date
     ,a.last_update_login       AS last_update_login
     ,a.request_id              AS request_id
     ,a.program_application_id  AS program_application_id
     ,a.program_id              AS program_id
     ,a.program_update_date     AS program_update_date
     ,'D'                       AS record_type
    FROM
      xxcmm_system_items_b_hst  a
    WHERE NOT EXISTS(
      SELECT 1
      FROM   xxcmm_system_items_b_hst@t4_hon b
      WHERE  b.item_hst_id = a.item_hst_id
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.item_hst_id             AS item_hst_id
     ,a.item_id                 AS item_id
     ,a.item_code               AS item_code
     ,a.apply_date              AS apply_date
     ,a.apply_flag              AS apply_flag
     ,a.item_status             AS item_status
     ,a.policy_group            AS policy_group
     ,a.fixed_price             AS fixed_price
     ,a.discrete_cost           AS discrete_cost
     ,a.first_apply_flag        AS first_apply_flag
     ,a.created_by              AS created_by
     ,a.creation_date           AS creation_date
     ,a.last_updated_by         AS last_updated_by
     ,a.last_update_date        AS last_update_date
     ,a.last_update_login       AS last_update_login
     ,a.request_id              AS request_id
     ,a.program_application_id  AS program_application_id
     ,a.program_id              AS program_id
     ,a.program_update_date     AS program_update_date
     ,'U'                       AS record_type
    FROM(
      SELECT
        xsibh.item_hst_id             AS item_hst_id
       ,NULL                          AS item_id
       ,xsibh.item_code               AS item_code
       ,xsibh.apply_date              AS apply_date
       ,xsibh.apply_flag              AS apply_flag
       ,xsibh.item_status             AS item_status
       ,xsibh.policy_group            AS policy_group
       ,xsibh.fixed_price             AS fixed_price
       ,xsibh.discrete_cost           AS discrete_cost
       ,xsibh.first_apply_flag        AS first_apply_flag
       ,xsibh.created_by              AS created_by
       ,xsibh.creation_date           AS creation_date
       ,xsibh.last_updated_by         AS last_updated_by
       ,xsibh.last_update_date        AS last_update_date
       ,xsibh.last_update_login       AS last_update_login
       ,xsibh.request_id              AS request_id
       ,xsibh.program_application_id  AS program_application_id
       ,xsibh.program_id              AS program_id
       ,xsibh.program_update_date     AS program_update_date
      FROM
        xxcmm_system_items_b_hst@t4_hon  xsibh
      MINUS
        SELECT
          xsibh.item_hst_id             AS item_hst_id
         ,NULL                          AS item_id
         ,xsibh.item_code               AS item_code
         ,xsibh.apply_date              AS apply_date
         ,xsibh.apply_flag              AS apply_flag
         ,xsibh.item_status             AS item_status
         ,xsibh.policy_group            AS policy_group
         ,xsibh.fixed_price             AS fixed_price
         ,xsibh.discrete_cost           AS discrete_cost
         ,xsibh.first_apply_flag        AS first_apply_flag
         ,xsibh.created_by              AS created_by
         ,xsibh.creation_date           AS creation_date
         ,xsibh.last_updated_by         AS last_updated_by
         ,xsibh.last_update_date        AS last_update_date
         ,xsibh.last_update_login       AS last_update_login
         ,xsibh.request_id              AS request_id
         ,xsibh.program_application_id  AS program_application_id
         ,xsibh.program_id              AS program_id
         ,xsibh.program_update_date     AS program_update_date
        FROM
          xxcmm_system_items_b_hst  xsibh
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM xxcmm_system_items_b_hst  b
      WHERE b.item_hst_id = a.item_hst_id
    )
  ;
  TYPE get_xsibh_ttype IS TABLE OF xxccp_xcmm_system_items_b_hst%ROWTYPE INDEX BY BINARY_INTEGER;
  get_xsibh_tab get_xsibh_ttype;
--
  -- DISC�i�ڌ����������oSQL
  CURSOR get_cicd_cur
  IS
    --�ǉ�
    SELECT
      a.inventory_item_id              AS inventory_item_id
     ,a2.segment1                      AS item_no
     ,a.organization_id                AS organization_id
     ,a.cost_type_id                   AS cost_type_id
     ,cd_last_update_date              AS last_update_date
     ,cn_last_updated_by               AS last_updated_by
     ,cd_creation_date                 AS creation_date
     ,cn_created_by                    AS created_by
     ,cn_last_update_login             AS last_update_login
     ,a.operation_sequence_id          AS operation_sequence_id
     ,a.operation_seq_num              AS operation_seq_num
     ,a.department_id                  AS department_id
     ,a.level_type                     AS level_type
     ,a.activity_id                    AS activity_id
     ,a.resource_seq_num               AS resource_seq_num
     ,a.resource_id                    AS resource_id
     ,a.resource_rate                  AS resource_rate
     ,a.item_units                     AS item_units
     ,a.activity_units                 AS activity_units
     ,a.usage_rate_or_amount           AS usage_rate_or_amount
     ,a.basis_type                     AS basis_type
     ,a.basis_resource_id              AS basis_resource_id
     ,a.basis_factor                   AS basis_factor
     ,a.net_yield_or_shrinkage_factor  AS net_yield_or_shrinkage_factor
     ,a.item_cost                      AS item_cost
     ,a.cost_element_id                AS cost_element_id
     ,a.rollup_source_type             AS rollup_source_type
     ,a.activity_context               AS activity_context
     ,cn_request_id                    AS request_id
     ,cn_program_application_id        AS program_application_id
     ,cn_program_id                    AS program_id
     ,cd_program_update_date           AS program_update_date
     ,a.attribute_category             AS attribute_category
     ,a.attribute1                     AS attribute1
     ,a.attribute2                     AS attribute2
     ,a.attribute3                     AS attribute3
     ,a.attribute4                     AS attribute4
     ,a.attribute5                     AS attribute5
     ,a.attribute6                     AS attribute6
     ,a.attribute7                     AS attribute7
     ,a.attribute8                     AS attribute8
     ,a.attribute9                     AS attribute9
     ,a.attribute10                    AS attribute10
     ,a.attribute11                    AS attribute11
     ,a.attribute12                    AS attribute12
     ,a.attribute13                    AS attribute13
     ,a.attribute14                    AS attribute14
     ,a.attribute15                    AS attribute15
     ,a.yielded_cost                   AS yielded_cost
     ,a.source_organization_id         AS source_organization_id
     ,a.vendor_id                      AS vendor_id
     ,a.allocation_percent             AS allocation_percent
     ,a.vendor_site_id                 AS vendor_site_id
     ,a.ship_method                    AS ship_method
     ,'I'                              AS record_type
    FROM
      cst_item_cost_details@t4_hon  a
     ,(SELECT m.*
       FROM   mtl_system_items_b@t4_hon m
       WHERE  m.organization_id = gt_org_id_hon
      )                             a2
    WHERE a.cost_type_id      = 1000
      AND a.inventory_item_id = a2.inventory_item_id
      AND a.organization_id   = a2.organization_id
      AND NOT EXISTS(
        SELECT 1
        FROM   cst_item_cost_details b
              ,(SELECT m.*
                FROM   mtl_system_items_b m
                WHERE  m.organization_id = gt_org_id_t4
               )                     b2
        WHERE  b.cost_type_id      = 1000
          AND  b.inventory_item_id = b2.inventory_item_id
          AND  b.organization_id   = b2.organization_id
          AND  b2.segment1         = a2.segment1
          AND  b.cost_type_id      = a.cost_type_id
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.inventory_item_id              AS inventory_item_id
     ,a.segment1                       AS item_no
     ,a.organization_id                AS organization_id
     ,a.cost_type_id                   AS cost_type_id
     ,a.last_update_date               AS last_update_date
     ,a.last_updated_by                AS last_updated_by
     ,a.creation_date                  AS creation_date
     ,a.created_by                     AS created_by
     ,a.last_update_login              AS last_update_login
     ,a.operation_sequence_id          AS operation_sequence_id
     ,a.operation_seq_num              AS operation_seq_num
     ,a.department_id                  AS department_id
     ,a.level_type                     AS level_type
     ,a.activity_id                    AS activity_id
     ,a.resource_seq_num               AS resource_seq_num
     ,a.resource_id                    AS resource_id
     ,a.resource_rate                  AS resource_rate
     ,a.item_units                     AS item_units
     ,a.activity_units                 AS activity_units
     ,a.usage_rate_or_amount           AS usage_rate_or_amount
     ,a.basis_type                     AS basis_type
     ,a.basis_resource_id              AS basis_resource_id
     ,a.basis_factor                   AS basis_factor
     ,a.net_yield_or_shrinkage_factor  AS net_yield_or_shrinkage_factor
     ,a.item_cost                      AS item_cost
     ,a.cost_element_id                AS cost_element_id
     ,a.rollup_source_type             AS rollup_source_type
     ,a.activity_context               AS activity_context
     ,a.request_id                     AS request_id
     ,a.program_application_id         AS program_application_id
     ,a.program_id                     AS program_id
     ,a.program_update_date            AS program_update_date
     ,a.attribute_category             AS attribute_category
     ,a.attribute1                     AS attribute1
     ,a.attribute2                     AS attribute2
     ,a.attribute3                     AS attribute3
     ,a.attribute4                     AS attribute4
     ,a.attribute5                     AS attribute5
     ,a.attribute6                     AS attribute6
     ,a.attribute7                     AS attribute7
     ,a.attribute8                     AS attribute8
     ,a.attribute9                     AS attribute9
     ,a.attribute10                    AS attribute10
     ,a.attribute11                    AS attribute11
     ,a.attribute12                    AS attribute12
     ,a.attribute13                    AS attribute13
     ,a.attribute14                    AS attribute14
     ,a.attribute15                    AS attribute15
     ,a.yielded_cost                   AS yielded_cost
     ,a.source_organization_id         AS source_organization_id
     ,a.vendor_id                      AS vendor_id
     ,a.allocation_percent             AS allocation_percent
     ,a.vendor_site_id                 AS vendor_site_id
     ,a.ship_method                    AS ship_method
     ,'U'                              AS record_type
    FROM(
      SELECT
        NULL                                AS inventory_item_id
       ,msib.segment1                       AS segment1
       ,NULL                                AS organization_id
       ,cicd.cost_type_id                   AS cost_type_id
       ,cd_last_update_date                 AS last_update_date
       ,cn_last_updated_by                  AS last_updated_by
       ,cd_creation_date                    AS creation_date
       ,cn_created_by                       AS created_by
       ,cn_last_update_login                AS last_update_login
       ,cicd.operation_sequence_id          AS operation_sequence_id
       ,cicd.operation_seq_num              AS operation_seq_num
       ,cicd.department_id                  AS department_id
       ,cicd.level_type                     AS level_type
       ,cicd.activity_id                    AS activity_id
       ,cicd.resource_seq_num               AS resource_seq_num
       ,cicd.resource_id                    AS resource_id
       ,cicd.resource_rate                  AS resource_rate
       ,cicd.item_units                     AS item_units
       ,cicd.activity_units                 AS activity_units
       ,cicd.usage_rate_or_amount           AS usage_rate_or_amount
       ,cicd.basis_type                     AS basis_type
       ,cicd.basis_resource_id              AS basis_resource_id
       ,cicd.basis_factor                   AS basis_factor
       ,cicd.net_yield_or_shrinkage_factor  AS net_yield_or_shrinkage_factor
       ,cicd.item_cost                      AS item_cost
       ,cicd.cost_element_id                AS cost_element_id
       ,cicd.rollup_source_type             AS rollup_source_type
       ,cicd.activity_context               AS activity_context
       ,cn_request_id                       AS request_id
       ,cn_program_application_id           AS program_application_id
       ,cn_program_id                       AS program_id
       ,cd_program_update_date              AS program_update_date
       ,cicd.attribute_category             AS attribute_category
       ,cicd.attribute1                     AS attribute1
       ,cicd.attribute2                     AS attribute2
       ,cicd.attribute3                     AS attribute3
       ,cicd.attribute4                     AS attribute4
       ,cicd.attribute5                     AS attribute5
       ,cicd.attribute6                     AS attribute6
       ,cicd.attribute7                     AS attribute7
       ,cicd.attribute8                     AS attribute8
       ,cicd.attribute9                     AS attribute9
       ,cicd.attribute10                    AS attribute10
       ,cicd.attribute11                    AS attribute11
       ,cicd.attribute12                    AS attribute12
       ,cicd.attribute13                    AS attribute13
       ,cicd.attribute14                    AS attribute14
       ,cicd.attribute15                    AS attribute15
       ,cicd.yielded_cost                   AS yielded_cost
       ,cicd.source_organization_id         AS source_organization_id
       ,cicd.vendor_id                      AS vendor_id
       ,cicd.allocation_percent             AS allocation_percent
       ,cicd.vendor_site_id                 AS vendor_site_id
       ,cicd.ship_method                    AS ship_method
      FROM
        cst_item_cost_details@t4_hon  cicd
       ,(SELECT m.*
         FROM   mtl_system_items_b@t4_hon m
         WHERE  m.organization_id = gt_org_id_hon
        )                             msib
      WHERE cicd.cost_type_id       = 1000
        AND cicd.inventory_item_id  = msib.inventory_item_id
        AND cicd.organization_id    = msib.organization_id
      MINUS
        SELECT
          NULL                                AS inventory_item_id
         ,msib.segment1                       AS segment1
         ,NULL                                AS organization_id
         ,cicd.cost_type_id                   AS cost_type_id
         ,cd_last_update_date                 AS last_update_date
         ,cn_last_updated_by                  AS last_updated_by
         ,cd_creation_date                    AS creation_date
         ,cn_created_by                       AS created_by
         ,cn_last_update_login                AS last_update_login
         ,cicd.operation_sequence_id          AS operation_sequence_id
         ,cicd.operation_seq_num              AS operation_seq_num
         ,cicd.department_id                  AS department_id
         ,cicd.level_type                     AS level_type
         ,cicd.activity_id                    AS activity_id
         ,cicd.resource_seq_num               AS resource_seq_num
         ,cicd.resource_id                    AS resource_id
         ,cicd.resource_rate                  AS resource_rate
         ,cicd.item_units                     AS item_units
         ,cicd.activity_units                 AS activity_units
         ,cicd.usage_rate_or_amount           AS usage_rate_or_amount
         ,cicd.basis_type                     AS basis_type
         ,cicd.basis_resource_id              AS basis_resource_id
         ,cicd.basis_factor                   AS basis_factor
         ,cicd.net_yield_or_shrinkage_factor  AS net_yield_or_shrinkage_factor
         ,cicd.item_cost                      AS item_cost
         ,cicd.cost_element_id                AS cost_element_id
         ,cicd.rollup_source_type             AS rollup_source_type
         ,cicd.activity_context               AS activity_context
         ,cn_request_id                       AS request_id
         ,cn_program_application_id           AS program_application_id
         ,cn_program_id                       AS program_id
         ,cd_program_update_date              AS program_update_date
         ,cicd.attribute_category             AS attribute_category
         ,cicd.attribute1                     AS attribute1
         ,cicd.attribute2                     AS attribute2
         ,cicd.attribute3                     AS attribute3
         ,cicd.attribute4                     AS attribute4
         ,cicd.attribute5                     AS attribute5
         ,cicd.attribute6                     AS attribute6
         ,cicd.attribute7                     AS attribute7
         ,cicd.attribute8                     AS attribute8
         ,cicd.attribute9                     AS attribute9
         ,cicd.attribute10                    AS attribute10
         ,cicd.attribute11                    AS attribute11
         ,cicd.attribute12                    AS attribute12
         ,cicd.attribute13                    AS attribute13
         ,cicd.attribute14                    AS attribute14
         ,cicd.attribute15                    AS attribute15
         ,cicd.yielded_cost                   AS yielded_cost
         ,cicd.source_organization_id         AS source_organization_id
         ,cicd.vendor_id                      AS vendor_id
         ,cicd.allocation_percent             AS allocation_percent
         ,cicd.vendor_site_id                 AS vendor_site_id
         ,cicd.ship_method                    AS ship_method
        FROM
          cst_item_cost_details  cicd
         ,(SELECT m.*
           FROM   mtl_system_items_b m
           WHERE  m.organization_id = gt_org_id_t4
          )                      msib
        WHERE cicd.cost_type_id       = 1000
          AND cicd.inventory_item_id  = msib.inventory_item_id
          AND cicd.organization_id    = msib.organization_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   cst_item_cost_details  b
            ,(SELECT m.*
              FROM   mtl_system_items_b m
              WHERE  m.organization_id = gt_org_id_t4
             )                      b2
      WHERE  b.cost_type_id      = 1000
        AND  b.inventory_item_id = b2.inventory_item_id
        AND  b.organization_id   = b2.organization_id
        AND  a.segment1          = b2.segment1
        AND  b.cost_type_id      = a.cost_type_id
    )
  ;
  TYPE get_cicd_ttype IS TABLE OF xxccp_cst_item_cost_details%ROWTYPE INDEX BY BINARY_INTEGER;
  get_cicd_tab get_cicd_ttype;
--
  -- �P�ʊ��Z�}�X�^�������oSQL
  CURSOR get_mucc_cur
  IS
    --�ǉ�
    SELECT
      a.inventory_item_id      AS inventory_item_id
     ,a2.segment1              AS item_no
     ,a.from_unit_of_measure   AS from_unit_of_measure
     ,a.from_uom_code          AS from_uom_code
     ,a.from_uom_class         AS from_uom_class
     ,a.to_unit_of_measure     AS to_unit_of_measure
     ,a.to_uom_code            AS to_uom_code
     ,a.to_uom_class           AS to_uom_class
     ,a.last_update_date       AS last_update_date
     ,a.last_updated_by        AS last_updated_by
     ,a.creation_date          AS creation_date
     ,a.created_by             AS created_by
     ,a.last_update_login      AS last_update_login
     ,a.conversion_rate        AS conversion_rate
     ,a.disable_date           AS disable_date
     ,a.request_id             AS request_id
     ,a.program_application_id AS program_application_id
     ,a.program_id             AS program_id
     ,a.program_update_date    AS program_update_date
     ,'I'                      AS record_type
    FROM
      mtl_uom_class_conversions@t4_hon  a
     ,(SELECT m.*
       FROM   mtl_system_items_b@t4_hon m
       WHERE  m.organization_id = gt_mst_org_id_hon
      )                                 a2
    WHERE a.inventory_item_id = a2.inventory_item_id
      AND NOT EXISTS(
        SELECT 1
          FROM mtl_uom_class_conversions b
              ,(SELECT m.*
                FROM   mtl_system_items_b m
                WHERE  m.organization_id = gt_mst_org_id_t4
               )                         b2
         WHERE b.inventory_item_id  = b2.inventory_item_id
           AND b2.segment1          = a2.segment1
           AND b.to_uom_code        = a.to_uom_code
           AND b.to_uom_class       = a.to_uom_class
    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.inventory_item_id      AS inventory_item_id
     ,a.segment1               AS item_no
     ,a.from_unit_of_measure   AS from_unit_of_measure
     ,a.from_uom_code          AS from_uom_code
     ,a.from_uom_class         AS from_uom_class
     ,a.to_unit_of_measure     AS to_unit_of_measure
     ,a.to_uom_code            AS to_uom_code
     ,a.to_uom_class           AS to_uom_class
     ,a.last_update_date       AS last_update_date
     ,a.last_updated_by        AS last_updated_by
     ,a.creation_date          AS creation_date
     ,a.created_by             AS created_by
     ,a.last_update_login      AS last_update_login
     ,a.conversion_rate        AS conversion_rate
     ,a.disable_date           AS disable_date
     ,a.request_id             AS request_id
     ,a.program_application_id AS program_application_id
     ,a.program_id             AS program_id
     ,a.program_update_date    AS program_update_date
     ,'U'                      AS record_type
    FROM(
      SELECT
        NULL                        AS inventory_item_id
       ,msib.segment1               AS segment1
       ,mucc.from_unit_of_measure   AS from_unit_of_measure
       ,mucc.from_uom_code          AS from_uom_code
       ,mucc.from_uom_class         AS from_uom_class
       ,mucc.to_unit_of_measure     AS to_unit_of_measure
       ,mucc.to_uom_code            AS to_uom_code
       ,mucc.to_uom_class           AS to_uom_class
       ,mucc.last_update_date       AS last_update_date
       ,mucc.last_updated_by        AS last_updated_by
       ,mucc.creation_date          AS creation_date
       ,mucc.created_by             AS created_by
       ,mucc.last_update_login      AS last_update_login
       ,mucc.conversion_rate        AS conversion_rate
       ,mucc.disable_date           AS disable_date
       ,mucc.request_id             AS request_id
       ,mucc.program_application_id AS program_application_id
       ,mucc.program_id             AS program_id
       ,mucc.program_update_date    AS program_update_date
      FROM
        mtl_uom_class_conversions@t4_hon  mucc
       ,(SELECT m.*
         FROM   mtl_system_items_b@t4_hon m
         WHERE  m.organization_id = gt_mst_org_id_hon
        )                                 msib
      WHERE mucc.inventory_item_id = msib.inventory_item_id
      MINUS
        SELECT
          NULL                        AS inventory_item_id
         ,msib.segment1               AS segment1
         ,mucc.from_unit_of_measure   AS from_unit_of_measure
         ,mucc.from_uom_code          AS from_uom_code
         ,mucc.from_uom_class         AS from_uom_class
         ,mucc.to_unit_of_measure     AS to_unit_of_measure
         ,mucc.to_uom_code            AS to_uom_code
         ,mucc.to_uom_class           AS to_uom_class
         ,mucc.last_update_date       AS last_update_date
         ,mucc.last_updated_by        AS last_updated_by
         ,mucc.creation_date          AS creation_date
         ,mucc.created_by             AS created_by
         ,mucc.last_update_login      AS last_update_login
         ,mucc.conversion_rate        AS conversion_rate
         ,mucc.disable_date           AS disable_date
         ,mucc.request_id             AS request_id
         ,mucc.program_application_id AS program_application_id
         ,mucc.program_id             AS program_id
         ,mucc.program_update_date    AS program_update_date
        FROM
          mtl_uom_class_conversions  mucc
         ,(SELECT m.*
           FROM   mtl_system_items_b m
           WHERE  m.organization_id = gt_mst_org_id_t4
          )                          msib
        WHERE mucc.inventory_item_id = msib.inventory_item_id
      ) a
    WHERE EXISTS(
      SELECT 1
      FROM   mtl_uom_class_conversions  b
            ,(SELECT m.*
              FROM   mtl_system_items_b m
              WHERE  m.organization_id = gt_mst_org_id_t4
             )                          b2
      WHERE  b.inventory_item_id  = b2.inventory_item_id
        AND  b2.segment1          = a.segment1
        AND  b.to_uom_code        = a.to_uom_code
        AND  b.to_uom_class       = a.to_uom_class
    )
  ;
  TYPE get_mucc_ttype IS TABLE OF xxccp_mtl_uom_class_convs%ROWTYPE INDEX BY BINARY_INTEGER;
  get_mucc_tab get_mucc_ttype;
--
  -- �i�ڃJ�e�S���������oSQL
  CURSOR get_mcb_cur
  IS
    --�ǉ�
    SELECT
      fifs.id_flex_structure_code  AS structure_code
     ,mcb.structure_id             AS structure_id
     ,mcb.segment1                 AS segment1
     ,mct.description              AS description
     ,mcb.disable_date             AS disable_date
     ,mcb.attribute_category       AS attribute_category
     ,mcb.attribute1               AS attribute1
     ,mcb.attribute2               AS attribute2
     ,mcb.attribute3               AS attribute3
     ,mcb.attribute4               AS attribute4
     ,mcb.attribute5               AS attribute5
     ,mcb.attribute6               AS attribute6
     ,mcb.attribute7               AS attribute7
     ,mcb.attribute8               AS attribute8
     ,mcb.attribute9               AS attribute9
     ,mcb.attribute10              AS attribute10
     ,mcb.attribute11              AS attribute11
     ,mcb.attribute12              AS attribute12
     ,mcb.attribute13              AS attribute13
     ,mcb.attribute14              AS attribute14
     ,mcb.attribute15              AS attribute15
     ,'I'                          AS record_type
    FROM
      mtl_categories_b@t4_hon        mcb
     ,mtl_categories_tl@t4_hon       mct
     ,mtl_category_sets_b@t4_hon     mcsb
     ,mtl_category_sets_tl@t4_hon    mcst
     ,fnd_id_flex_structures@t4_hon  fifs
    WHERE mcsb.structure_id    = mcb.structure_id
      AND mcb.category_id      = mct.category_id
      AND mct.language         = USERENV('LANG')
      AND mcb.enabled_flag     = 'Y'
      AND fifs.application_id  = 401
      AND fifs.id_flex_code    = 'MCAT'
      AND fifs.id_flex_num     = mcsb.structure_id
      AND mcsb.category_set_id = mcst.category_set_id
      AND mcst.language        = USERENV('LANG')
      AND fifs.id_flex_structure_code IN ('XXCMN_COMMODITYPRODUCT_CLASS'  -- ���i���i�敪
                                         ,'XXCMN_HQCOMMODITY_CLASS'       -- �{�Џ��i�敪
                                         ,'XXCMN_SGUN_CODE'               -- ����Q�R�[�h
                                         ,'XXCMN_TGUN_CODE'               -- �Q�R�[�h
                                         ,'XXCMN_MGUN_CODE'               -- �}�[�P�p�Q�R�[�h
                                         ,'XXCMN_ITEM_CLASS'              -- �i�ڋ敪
                                         ,'XXCMN_INOUT_CLASS'             -- ���O�敪
                                         ,'XXCMN_COMMODITY_CLASS'         -- ���i�敪
                                         ,'XXCMN_QUALITY_CLASS'           -- �i���敪
                                         ,'XXCMN_FGUN_CODE'               -- �H��Q�R�[�h
                                         ,'XXCMN_KGUN_CODE'               -- �o�����p�Q�R�[�h
                                         ,'XXCMN_ASUNDERTEA_CLASS'        -- �o�����敪
                                         )
      AND NOT EXISTS(SELECT 1
                     FROM   mtl_categories_b mcb2
                     WHERE  mcb2.structure_id = mcb.structure_id
                       AND  mcb2.segment1     = mcb.segment1
                    )
--
    UNION ALL
--
    --�X�V
    SELECT
      a.structure_code           AS structure_code
     ,a.structure_id             AS structure_id
     ,a.segment1                 AS segment1
     ,a.description              AS description
     ,a.disable_date             AS disable_date
     ,a.attribute_category       AS attribute_category
     ,a.attribute1               AS attribute1
     ,a.attribute2               AS attribute2
     ,a.attribute3               AS attribute3
     ,a.attribute4               AS attribute4
     ,a.attribute5               AS attribute5
     ,a.attribute6               AS attribute6
     ,a.attribute7               AS attribute7
     ,a.attribute8               AS attribute8
     ,a.attribute9               AS attribute9
     ,a.attribute10              AS attribute10
     ,a.attribute11              AS attribute11
     ,a.attribute12              AS attribute12
     ,a.attribute13              AS attribute13
     ,a.attribute14              AS attribute14
     ,a.attribute15              AS attribute15
     ,'U'                        AS record_type
    FROM(
      SELECT
        fifs.id_flex_structure_code  AS structure_code
       ,mcb.structure_id             AS structure_id
       ,mcb.segment1                 AS segment1
       ,mct.description              AS description
       ,mcb.disable_date             AS disable_date
       ,mcb.attribute_category       AS attribute_category
       ,mcb.attribute1               AS attribute1
       ,mcb.attribute2               AS attribute2
       ,mcb.attribute3               AS attribute3
       ,mcb.attribute4               AS attribute4
       ,mcb.attribute5               AS attribute5
       ,mcb.attribute6               AS attribute6
       ,mcb.attribute7               AS attribute7
       ,mcb.attribute8               AS attribute8
       ,mcb.attribute9               AS attribute9
       ,mcb.attribute10              AS attribute10
       ,mcb.attribute11              AS attribute11
       ,mcb.attribute12              AS attribute12
       ,mcb.attribute13              AS attribute13
       ,mcb.attribute14              AS attribute14
       ,mcb.attribute15              AS attribute15
      FROM
        mtl_categories_b@t4_hon        mcb
       ,mtl_categories_tl@t4_hon       mct
       ,mtl_category_sets_b@t4_hon     mcsb
       ,mtl_category_sets_tl@t4_hon    mcst
       ,fnd_id_flex_structures@t4_hon  fifs
      WHERE mcsb.structure_id    = mcb.structure_id
        AND mcb.category_id      = mct.category_id
        AND mct.language         = USERENV('LANG')
        AND mcb.enabled_flag     = 'Y'
        AND fifs.application_id  = 401
        AND fifs.id_flex_code    = 'MCAT'
        AND fifs.id_flex_num     = mcsb.structure_id
        AND mcsb.category_set_id = mcst.category_set_id
        AND mcst.language        = USERENV('LANG')
      MINUS
        SELECT
          fifs.id_flex_structure_code  AS structure_code
         ,mcb.structure_id             AS structure_id
         ,mcb.segment1                 AS segment1
         ,mct.description              AS description
         ,mcb.disable_date             AS disable_date
         ,mcb.attribute_category       AS attribute_category
         ,mcb.attribute1               AS attribute1
         ,mcb.attribute2               AS attribute2
         ,mcb.attribute3               AS attribute3
         ,mcb.attribute4               AS attribute4
         ,mcb.attribute5               AS attribute5
         ,mcb.attribute6               AS attribute6
         ,mcb.attribute7               AS attribute7
         ,mcb.attribute8               AS attribute8
         ,mcb.attribute9               AS attribute9
         ,mcb.attribute10              AS attribute10
         ,mcb.attribute11              AS attribute11
         ,mcb.attribute12              AS attribute12
         ,mcb.attribute13              AS attribute13
         ,mcb.attribute14              AS attribute14
         ,mcb.attribute15              AS attribute15
        FROM
          mtl_categories_b        mcb
         ,mtl_categories_tl       mct
         ,mtl_category_sets_b     mcsb
         ,mtl_category_sets_tl    mcst
         ,fnd_id_flex_structures  fifs
        WHERE mcsb.structure_id    = mcb.structure_id
          AND mcb.category_id      = mct.category_id
          AND mct.language         = USERENV('LANG')
          AND mcb.enabled_flag     = 'Y'
          AND fifs.application_id  = 401
          AND fifs.id_flex_code    = 'MCAT'
          AND fifs.id_flex_num     = mcsb.structure_id
          AND mcsb.category_set_id = mcst.category_set_id
          AND mcst.language        = USERENV('LANG')
        ) a
    WHERE EXISTS(SELECT 1
                 FROM   mtl_categories_b b
                 WHERE  b.structure_id = a.structure_id
                   AND  b.segment1     = a.segment1
    )
      AND a.structure_code IN ('XXCMN_COMMODITYPRODUCT_CLASS'  -- ���i���i�敪
                              ,'XXCMN_HQCOMMODITY_CLASS'       -- �{�Џ��i�敪
                              ,'XXCMN_SGUN_CODE'               -- ����Q�R�[�h
                              ,'XXCMN_TGUN_CODE'               -- �Q�R�[�h
                              ,'XXCMN_MGUN_CODE'               -- �}�[�P�p�Q�R�[�h
                              ,'XXCMN_ITEM_CLASS'              -- �i�ڋ敪
                              ,'XXCMN_INOUT_CLASS'             -- ���O�敪
                              ,'XXCMN_COMMODITY_CLASS'         -- ���i�敪
                              ,'XXCMN_QUALITY_CLASS'           -- �i���敪
                              ,'XXCMN_FGUN_CODE'               -- �H��Q�R�[�h
                              ,'XXCMN_KGUN_CODE'               -- �o�����p�Q�R�[�h
                              ,'XXCMN_ASUNDERTEA_CLASS'        -- �o�����敪
                              )
    ;
  TYPE get_mcb_ttype IS TABLE OF xxccp_mtl_categories_b%ROWTYPE INDEX BY BINARY_INTEGER;
  get_mcb_tab get_mcb_ttype;
--
  --
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���b�N�G���[��O ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : get_diff_record
   * Description      : �������R�[�h�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_diff_record(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_diff_record';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx_1   NUMBER;   -- FORALL�p
    ln_idx_2   NUMBER;   -- FORALL�p
    ln_idx_3   NUMBER;   -- FORALL�p
    ln_idx_4   NUMBER;   -- FORALL�p
    ln_idx_5   NUMBER;   -- FORALL�p
    ln_idx_6   NUMBER;   -- FORALL�p
    ln_idx_7   NUMBER;   -- FORALL�p
    ln_idx_8   NUMBER;   -- FORALL�p
    ln_idx_9   NUMBER;   -- FORALL�p
    ln_idx_10  NUMBER;   -- FORALL�p
    ln_idx_11  NUMBER;   -- FORALL�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- OPM�i�ڃ}�X�^�������o����
    -- ===============================
    OPEN get_iimb_cur;
    <<get_iimb_loop>>
    LOOP
      FETCH get_iimb_cur BULK COLLECT INTO get_iimb_tab LIMIT 10000;
      -- ===============================
      -- OPM�i�ڃ}�X�^�������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_1 IN 1..get_iimb_tab.COUNT
          INSERT INTO xxccp_ic_item_mst_b
          VALUES get_iimb_tab(ln_idx_1);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃ}�X�^�������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_iimb_tab.DELETE;
      EXIT WHEN get_iimb_cur%NOTFOUND;
    END LOOP get_iimb_loop;
    CLOSE get_iimb_cur;
--
    -- ===============================
    -- OPM�i�ڃA�h�I���}�X�^�������o����
    -- ===============================
    OPEN get_ximb_cur;
    <<get_ximb_loop>>
    LOOP
      FETCH get_ximb_cur BULK COLLECT INTO get_ximb_tab LIMIT 10000;
      -- ===============================
      -- OPM�i�ڃA�h�I���}�X�^�������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_2 IN 1..get_ximb_tab.COUNT
          INSERT INTO xxccp_xcmn_item_mst_b
          VALUES get_ximb_tab(ln_idx_2);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃA�h�I���}�X�^�������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_ximb_tab.DELETE;
      EXIT WHEN get_ximb_cur%NOTFOUND;
    END LOOP get_ximb_loop;
    CLOSE get_ximb_cur;
--
    -- ===============================
    -- OPM�i�ڃJ�e�S�������������o����
    -- ===============================
    OPEN get_gic_cur;
    <<get_gic_loop>>
    LOOP
      FETCH get_gic_cur BULK COLLECT INTO get_gic_tab LIMIT 10000;
      -- ===============================
      -- OPM�i�ڃJ�e�S�������������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_3 IN 1..get_gic_tab.COUNT
          INSERT INTO xxccp_gmi_item_categories
          VALUES get_gic_tab(ln_idx_3);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃJ�e�S�������������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_gic_tab.DELETE;
      EXIT WHEN get_gic_cur%NOTFOUND;
    END LOOP get_gic_loop;
    CLOSE get_gic_cur;
--
    -- ===============================
    -- OPM�i�ڌ����������o����
    -- ===============================
    OPEN get_ccd_cur;
    <<get_ccd_loop>>
    LOOP
      FETCH get_ccd_cur BULK COLLECT INTO get_ccd_tab LIMIT 10000;
      -- ===============================
      -- OPM�i�ڌ����������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_4 IN 1..get_ccd_tab.COUNT
          INSERT INTO xxccp_cm_cmpt_dtl
          VALUES get_ccd_tab(ln_idx_4);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڌ����������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_ccd_tab.DELETE;
      EXIT WHEN get_ccd_cur%NOTFOUND;
    END LOOP get_ccd_loop;
    CLOSE get_ccd_cur;
--
    -- ===============================
    -- DISC�i�ڃ}�X�^�������o����
    -- ===============================
    OPEN get_msib_cur;
    <<get_msib_loop>>
    LOOP
      FETCH get_msib_cur BULK COLLECT INTO get_msib_tab LIMIT 10000;
      -- ===============================
      -- DISC�i�ڃ}�X�^�������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_5 IN 1..get_msib_tab.COUNT
          INSERT INTO xxccp_mtl_system_items_b
          VALUES get_msib_tab(ln_idx_5);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'DISC�i�ڃ}�X�^�������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_msib_tab.DELETE;
      EXIT WHEN get_msib_cur%NOTFOUND;
    END LOOP get_msib_loop;
    CLOSE get_msib_cur;
--
    -- ===============================
    -- DISC�i�ڃA�h�I���}�X�^�������o����
    -- ===============================
    OPEN get_xsib_cur;
    <<get_xsib_loop>>
    LOOP
      FETCH get_xsib_cur BULK COLLECT INTO get_xsib_tab LIMIT 10000;
      -- ===============================
      -- DISC�i�ڃA�h�I���}�X�^�������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_6 IN 1..get_xsib_tab.COUNT
          INSERT INTO xxccp_xcmm_system_items_b
          VALUES get_xsib_tab(ln_idx_6);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'DISC�i�ڃA�h�I���}�X�^�������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_xsib_tab.DELETE;
      EXIT WHEN get_xsib_cur%NOTFOUND;
    END LOOP get_xsib_loop;
    CLOSE get_xsib_cur;
--
    -- ===============================
    -- DISC�i�ڃJ�e�S�������������o����
    -- ===============================
    OPEN get_mic_cur;
    <<get_mic_loop>>
    LOOP
      FETCH get_mic_cur BULK COLLECT INTO get_mic_tab LIMIT 10000;
      -- ===============================
      -- DISC�i�ڃJ�e�S�������������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_7 IN 1..get_mic_tab.COUNT
          INSERT INTO xxccp_mtl_item_categories
          VALUES get_mic_tab(ln_idx_7);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'DISC�i�ڃJ�e�S�������������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
     END;
      get_mic_tab.DELETE;
      EXIT WHEN get_mic_cur%NOTFOUND;
    END LOOP get_mic_loop;
    CLOSE get_mic_cur;
--
    -- ===============================
    -- DISC�i�ڕύX�����A�h�I���������o����
    -- ===============================
    OPEN get_xsibh_cur;
    <<get_xsibh_loop>>
    LOOP
      FETCH get_xsibh_cur BULK COLLECT INTO get_xsibh_tab LIMIT 10000;
      -- ===============================
      -- DISC�i�ڕύX�����A�h�I���������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_8 IN 1..get_xsibh_tab.COUNT
          INSERT INTO xxccp_xcmm_system_items_b_hst
          VALUES get_xsibh_tab(ln_idx_8);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'DISC�i�ڕύX�����A�h�I���������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_xsibh_tab.DELETE;
      EXIT WHEN get_xsibh_cur%NOTFOUND;
    END LOOP get_xsibh_loop;
    CLOSE get_xsibh_cur;
--
    -- ===============================
    -- DISC�i�ڌ����������o����
    -- ===============================
    OPEN get_cicd_cur;
    <<get_cicd_loop>>
    LOOP
      FETCH get_cicd_cur BULK COLLECT INTO get_cicd_tab LIMIT 10000;
      -- ===============================
      -- DISC�i�ڌ����������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_9 IN 1..get_cicd_tab.COUNT
          INSERT INTO xxccp_cst_item_cost_details
          VALUES get_cicd_tab(ln_idx_9);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'DISC�i�ڌ����������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_cicd_tab.DELETE;
      EXIT WHEN get_cicd_cur%NOTFOUND;
    END LOOP get_cicd_loop;
    CLOSE get_cicd_cur;
--
    -- ===============================
    -- �P�ʊ��Z�}�X�^�������o����
    -- ===============================
    OPEN get_mucc_cur;
    <<get_mucc_loop>>
    LOOP
      FETCH get_mucc_cur BULK COLLECT INTO get_mucc_tab LIMIT 10000;
      -- ===============================
      -- �P�ʊ��Z�}�X�^�������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_10 IN 1..get_mucc_tab.COUNT
          INSERT INTO xxccp_mtl_uom_class_convs
          VALUES get_mucc_tab(ln_idx_10);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�P�ʊ��Z�}�X�^�������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_mucc_tab.DELETE;
      EXIT WHEN get_mucc_cur%NOTFOUND;
    END LOOP get_mucc_loop;
    CLOSE get_mucc_cur;
--
    -- ===============================
    -- �i�ڃJ�e�S���������o����
    -- ===============================
    OPEN get_mcb_cur;
    <<get_mcb_loop>>
    LOOP
      FETCH get_mcb_cur BULK COLLECT INTO get_mcb_tab LIMIT 10000;
      -- ===============================
      -- �i�ڃJ�e�S���������R�[�h�o�^����
      -- ===============================
      BEGIN
        FORALL ln_idx_11 IN 1..get_mcb_tab.COUNT
          INSERT INTO xxccp_mtl_categories_b
          VALUES get_mcb_tab(ln_idx_11);
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i�ڃJ�e�S���������R�[�h�o�^�Ɏ��s���܂����B';
          RAISE global_api_others_expt;
      END;
      get_mcb_tab.DELETE;
      EXIT WHEN get_mcb_cur%NOTFOUND;
    END LOOP get_mcb_loop;
    CLOSE get_mcb_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_diff_record;
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_lkp
   * Description      : LOOKUP�\�L���`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exists_lkp(
    iv_lookup_type  IN  VARCHAR2
   ,iv_lookup_code  IN  VARCHAR2
   ,iv_key_info     IN  VARCHAR2
   ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_lkp';            -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_lookup_code   fnd_lookup_values_vl.lookup_code%TYPE;   --�`�F�b�N�p�_�~�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      SELECT flvv.lookup_code AS lookup_code
      INTO   lt_lookup_code
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type     = iv_lookup_type
        AND (
               --��P�ʂ̂݁u���e�v�Ŏ擾
              ( flvv.lookup_type  = 'XXCMM_UNITS_OF_MEASURE'
           AND  flvv.meaning      = iv_lookup_code )
         OR
               --��P�ʈȊO�́u�R�[�h�v�Ŏ擾
              ( flvv.lookup_type <> 'XXCMM_UNITS_OF_MEASURE'
           AND  flvv.lookup_code  = iv_lookup_code )
        )
        AND  flvv.enabled_flag    = 'Y'
        AND  gd_process_date     >= NVL( flvv.start_date_active, gd_process_date )
        AND  gd_process_date     <= NVL( flvv.end_date_active  , gd_process_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   =>   'LOOKUP�\�̎擾�Ɏ��s���܂����B'
                    ||'�Q�ƃ^�C�v��'||iv_lookup_type||'�A'
                    ||'�Q�ƃR�[�h��'||iv_lookup_code||'�A'
                    ||'�L�[����'  ||iv_key_info
        );
        --LOOKUP�\�`�F�b�N���^�[���E�R�[�h��ݒ�
        gv_chk_retcode := cv_status_warn;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_exists_lkp;
--
  /**********************************************************************************
   * Procedure Name   : proc_mcb
   * Description      : �i�ڃJ�e�S���o�^�E�X�V(A-3)
   ***********************************************************************************/
  PROCEDURE proc_mcb(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mcb';    -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    l_category_id     NUMBER;
    lt_category_id    mtl_categories_b.category_id%TYPE;   --�J�e�S��ID
--
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_return_status  VARCHAR2(200);
    ln_errorcode      NUMBER;
    l_msg_index_out   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xmcb_cur IS
      SELECT
        xmcb.*
      FROM
        xxccp_mtl_categories_b xmcb
      ORDER BY
        xmcb.structure_code
       ,xmcb.segment1
    ;
    TYPE l_xmcb_ttype IS TABLE OF xxccp_mtl_categories_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xmcb_rec l_xmcb_ttype;
--
    -- *** ���[�J���E���R�[�h ***
    l_category_rec  inv_item_category_pub.category_rec_type;
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xmcb_cur;
    FETCH l_xmcb_cur BULK COLLECT INTO l_xmcb_rec;
    CLOSE l_xmcb_cur;
--
    << xmcb_loop >>
    FOR i IN 1..l_xmcb_rec.COUNT LOOP
      --������
      l_category_rec := NULL;
      lv_msg_data    := NULL;
      --
      l_category_rec.segment1           := l_xmcb_rec(i).segment1;
      l_category_rec.description        := l_xmcb_rec(i).description;
      l_category_rec.disable_date       := l_xmcb_rec(i).disable_date;
      l_category_rec.attribute1         := l_xmcb_rec(i).attribute1;
      l_category_rec.attribute2         := l_xmcb_rec(i).attribute2;
      l_category_rec.attribute3         := l_xmcb_rec(i).attribute3;
      l_category_rec.attribute4         := l_xmcb_rec(i).attribute4;
      l_category_rec.attribute5         := l_xmcb_rec(i).attribute5;
      l_category_rec.attribute6         := l_xmcb_rec(i).attribute6;
      l_category_rec.attribute7         := l_xmcb_rec(i).attribute7;
      l_category_rec.attribute8         := l_xmcb_rec(i).attribute8;
      l_category_rec.attribute9         := l_xmcb_rec(i).attribute9;
      l_category_rec.attribute10        := l_xmcb_rec(i).attribute10;
      l_category_rec.attribute11        := l_xmcb_rec(i).attribute11;
      l_category_rec.attribute12        := l_xmcb_rec(i).attribute12;
      l_category_rec.attribute13        := l_xmcb_rec(i).attribute13;
      l_category_rec.attribute14        := l_xmcb_rec(i).attribute14;
      l_category_rec.attribute15        := l_xmcb_rec(i).attribute15;
      l_category_rec.attribute_category := l_xmcb_rec(i).attribute_category;
      l_category_rec.summary_flag       := 'N';    -- 'N'�Œ�
      l_category_rec.enabled_flag       := 'Y';    -- 'Y'�Œ�
      -- ===============================
      -- �o�^�̏ꍇ
      -- ===============================
      IF ( l_xmcb_rec(i).record_type = 'I' ) THEN
        --API�o�^�p���R�[�h�Z�b�g
        l_category_rec.structure_code := l_xmcb_rec(i).structure_code;
        --
        inv_item_category_pub.create_category(
           p_api_version       => 1.0
          ,p_init_msg_list     => FND_API.G_TRUE
          ,p_commit            => FND_API.G_FALSE
          ,p_category_rec      => l_category_rec
          ,x_category_id       => l_category_id
          ,x_return_status     => lv_return_status
          ,x_errorcode         => ln_errorcode
          ,x_msg_count         => ln_msg_count
          ,x_msg_data          => lv_msg_data
        );
        -- �G���[����
        IF ( lv_return_status <> 'S' ) THEN
          FOR l_msg_index IN 1..ln_msg_count
          LOOP  
            FND_MSG_PUB.GET(
              p_msg_index     => l_msg_index
            , p_encoded       => FND_API.G_FALSE
            , p_data          => lv_msg_data
            , p_msg_index_out => l_msg_index_out
            );
          END LOOP;
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i�ڃJ�e�S���o�^�Ɏ��s���܂����B'
                     ||'�ڍׁ�'||lv_msg_data;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- �o�^�����J�E���g
        gn_mcb_i_cnt := gn_mcb_i_cnt + 1;
      -- ===============================
      -- �X�V�̏ꍇ
      -- ===============================
      ELSE
        -- ===============================
        -- �J�e�S��ID�擾
        -- ===============================
        BEGIN
          SELECT mcb.category_id AS category_id
          INTO   lt_category_id
          FROM   mtl_categories_b mcb
          WHERE  mcb.structure_id = l_xmcb_rec(i).structure_id
            AND  mcb.segment1     = l_xmcb_rec(i).segment1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := '�J�e�S��ID�̎擾�Ɏ��s���܂����B'
                       ||'�J�e�S���E�R�[�h��'||l_xmcb_rec(i).structure_code||'�A'
                       ||'�J�e�S���l��'||l_xmcb_rec(i).segment1;
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
        --API�X�V�p���R�[�h�Z�b�g
        l_category_rec.category_id := lt_category_id;
        --
        inv_item_category_pub.update_category(
           p_api_version       => 1.0
          ,p_init_msg_list     => FND_API.G_TRUE
          ,p_commit            => FND_API.G_FALSE
          ,p_category_rec      => l_category_rec
          ,x_return_status     => lv_return_status
          ,x_errorcode         => ln_errorcode
          ,x_msg_count         => ln_msg_count
          ,x_msg_data          => lv_msg_data
        );
        -- �G���[����
        IF ( lv_return_status <> 'S' ) THEN
          FOR l_msg_index IN 1..ln_msg_count
          LOOP  
            FND_MSG_PUB.GET(
              p_msg_index     => l_msg_index
            , p_encoded       => FND_API.G_FALSE
            , p_data          => lv_msg_data
            , p_msg_index_out => l_msg_index_out
            );
          END LOOP;
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i�ڃJ�e�S���X�V�Ɏ��s���܂����B'
                     ||'�ڍׁ�'||lv_msg_data;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- �X�V�����J�E���g
        gn_mcb_u_cnt := gn_mcb_u_cnt + 1;
      END IF;
    --
    END LOOP xiimb_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_mcb;
--
  /**********************************************************************************
   * Procedure Name   : proc_iimb
   * Description      : OPM�i�ڃ}�X�^�o�^�E�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE proc_iimb(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_iimb';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id         ic_item_mst_b.item_id%TYPE;      -- �i��ID�i�[�p
    lt_whse_item_id    ic_item_mst_b.whse_item_id%TYPE; -- �q�ɕi��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xiimb_cur IS
      SELECT
        xiimb.*
      FROM
        xxccp_ic_item_mst_b xiimb
      ORDER BY
        xiimb.record_type
       ,CASE WHEN xiimb.item_no = xiimb.whse_item_no
          THEN 1
          ELSE 2
        END
       ,xiimb.item_no
    ;
    TYPE l_xiimb_ttype IS TABLE OF xxccp_ic_item_mst_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xiimb_rec l_xiimb_ttype;
--
    -- *** ���[�J���E���R�[�h ***
    l_iimb_rec  ic_item_mst_b%ROWTYPE;
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xiimb_cur;
    FETCH l_xiimb_cur BULK COLLECT INTO l_xiimb_rec;
    CLOSE l_xiimb_cur;
--
    << xiimb_loop >>
    FOR i IN 1..l_xiimb_rec.COUNT LOOP
      -- ������
      l_iimb_rec := NULL;
      --
      -- ===============================
      -- �o�^�̏ꍇ
      -- ===============================
      IF ( l_xiimb_rec(i).record_type = 'I' ) THEN
        --
        -- ===============================
        -- �i��ID�擾
        -- ===============================
        BEGIN
          -- �������R�[�h�ŕi��ID�g�p�`�F�b�N
          SELECT iimb.item_id AS item_id
          INTO   lt_item_id
          FROM   ic_item_mst_b iimb
          WHERE  iimb.item_id = l_xiimb_rec(i).item_id
          ;
          -- �g�p����Ă���ꍇ�̓V�[�P���X����̔�
          SELECT gem5_item_id_s.NEXTVAL AS item_id
          INTO   lt_item_id
          FROM   dual
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �g�p����Ă��Ȃ��ꍇ�͂��̂܂ܐݒ�
            lt_item_id := l_xiimb_rec(i).item_id;
        END;
        -- ===============================
        -- �q�ɕi��ID�擾
        -- ===============================
        IF ( l_xiimb_rec(i).item_no = l_xiimb_rec(i).whse_item_no ) THEN
          -- �V�K���R�[�h���l�����Ă��̂܂ܐݒ�
          lt_whse_item_id := lt_item_id;
        ELSE
          -- OPM�i�ڂ���擾
          SELECT iimb.item_id AS whse_item_id
          INTO   lt_whse_item_id
          FROM   ic_item_mst_b iimb
          WHERE  iimb.item_no = l_xiimb_rec(i).whse_item_no
          ;
        END IF;
      --
      -- ===============================
      -- �X�V�̏ꍇ
      -- ===============================
      ELSE
        -- ===============================
        -- �i��ID�擾
        -- ===============================
        SELECT iimb.item_id AS item_id
        INTO   lt_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xiimb_rec(i).item_no
        ;
        --
        -- ===============================
        -- �q�ɕi��ID�擾
        -- ===============================
        SELECT iimb.item_id AS whse_item_id
        INTO   lt_whse_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xiimb_rec(i).whse_item_no
        ;
      END IF;
--
      --API�o�^�p���R�[�h�Z�b�g
      l_iimb_rec.item_id                  := lt_item_id;
      l_iimb_rec.item_no                  := l_xiimb_rec(i).item_no;
      l_iimb_rec.item_desc1               := l_xiimb_rec(i).item_desc1;
      l_iimb_rec.item_desc2               := l_xiimb_rec(i).item_desc2;
      l_iimb_rec.alt_itema                := l_xiimb_rec(i).alt_itema;
      l_iimb_rec.alt_itemb                := l_xiimb_rec(i).alt_itemb;
      l_iimb_rec.item_um                  := l_xiimb_rec(i).item_um;
      l_iimb_rec.dualum_ind               := l_xiimb_rec(i).dualum_ind;
      l_iimb_rec.item_um2                 := l_xiimb_rec(i).item_um2;
      l_iimb_rec.deviation_lo             := l_xiimb_rec(i).deviation_lo;
      l_iimb_rec.deviation_hi             := l_xiimb_rec(i).deviation_hi;
      l_iimb_rec.level_code               := l_xiimb_rec(i).level_code;
      l_iimb_rec.lot_ctl                  := l_xiimb_rec(i).lot_ctl;
      l_iimb_rec.lot_indivisible          := l_xiimb_rec(i).lot_indivisible;
      l_iimb_rec.sublot_ctl               := l_xiimb_rec(i).sublot_ctl;
      l_iimb_rec.loct_ctl                 := l_xiimb_rec(i).loct_ctl;
      l_iimb_rec.noninv_ind               := l_xiimb_rec(i).noninv_ind;
      l_iimb_rec.match_type               := l_xiimb_rec(i).match_type;
      l_iimb_rec.inactive_ind             := l_xiimb_rec(i).inactive_ind;
      l_iimb_rec.inv_type                 := l_xiimb_rec(i).inv_type;
      l_iimb_rec.shelf_life               := l_xiimb_rec(i).shelf_life;
      l_iimb_rec.retest_interval          := l_xiimb_rec(i).retest_interval;
      l_iimb_rec.gl_class                 := l_xiimb_rec(i).gl_class;
      l_iimb_rec.inv_class                := l_xiimb_rec(i).inv_class;
      l_iimb_rec.sales_class              := l_xiimb_rec(i).sales_class;
      l_iimb_rec.ship_class               := l_xiimb_rec(i).ship_class;
      l_iimb_rec.frt_class                := l_xiimb_rec(i).frt_class;
      l_iimb_rec.price_class              := l_xiimb_rec(i).price_class;
      l_iimb_rec.storage_class            := l_xiimb_rec(i).storage_class;
      l_iimb_rec.purch_class              := l_xiimb_rec(i).purch_class;
      l_iimb_rec.tax_class                := l_xiimb_rec(i).tax_class;
      l_iimb_rec.customs_class            := l_xiimb_rec(i).customs_class;
      l_iimb_rec.alloc_class              := l_xiimb_rec(i).alloc_class;
      l_iimb_rec.planning_class           := l_xiimb_rec(i).planning_class;
      l_iimb_rec.itemcost_class           := l_xiimb_rec(i).itemcost_class;
      l_iimb_rec.cost_mthd_code           := l_xiimb_rec(i).cost_mthd_code;
      l_iimb_rec.upc_code                 := l_xiimb_rec(i).upc_code;
      l_iimb_rec.grade_ctl                := l_xiimb_rec(i).grade_ctl;
      l_iimb_rec.status_ctl               := l_xiimb_rec(i).status_ctl;
      l_iimb_rec.qc_grade                 := l_xiimb_rec(i).qc_grade;
      l_iimb_rec.lot_status               := l_xiimb_rec(i).lot_status;
      l_iimb_rec.bulk_id                  := l_xiimb_rec(i).bulk_id;
      l_iimb_rec.pkg_id                   := l_xiimb_rec(i).pkg_id;
      l_iimb_rec.qcitem_id                := l_xiimb_rec(i).qcitem_id;
      l_iimb_rec.qchold_res_code          := l_xiimb_rec(i).qchold_res_code;
      l_iimb_rec.expaction_code           := l_xiimb_rec(i).expaction_code;
      l_iimb_rec.fill_qty                 := l_xiimb_rec(i).fill_qty;
      l_iimb_rec.fill_um                  := l_xiimb_rec(i).fill_um;
      l_iimb_rec.expaction_interval       := l_xiimb_rec(i).expaction_interval;
      l_iimb_rec.phantom_type             := l_xiimb_rec(i).phantom_type;
      l_iimb_rec.whse_item_id             := lt_whse_item_id;
      l_iimb_rec.experimental_ind         := l_xiimb_rec(i).experimental_ind;
      l_iimb_rec.exported_date            := l_xiimb_rec(i).exported_date;
      l_iimb_rec.trans_cnt                := l_xiimb_rec(i).trans_cnt;
      l_iimb_rec.delete_mark              := l_xiimb_rec(i).delete_mark;
      l_iimb_rec.text_code                := l_xiimb_rec(i).text_code;
      l_iimb_rec.seq_dpnd_class           := l_xiimb_rec(i).seq_dpnd_class;
      l_iimb_rec.commodity_code           := l_xiimb_rec(i).commodity_code;
      l_iimb_rec.attribute1               := l_xiimb_rec(i).attribute1;
      l_iimb_rec.attribute2               := l_xiimb_rec(i).attribute2;
      l_iimb_rec.attribute3               := l_xiimb_rec(i).attribute3;
      l_iimb_rec.attribute4               := l_xiimb_rec(i).attribute4;
      l_iimb_rec.attribute5               := l_xiimb_rec(i).attribute5;
      l_iimb_rec.attribute6               := l_xiimb_rec(i).attribute6;
      l_iimb_rec.attribute7               := l_xiimb_rec(i).attribute7;
      l_iimb_rec.attribute8               := l_xiimb_rec(i).attribute8;
      l_iimb_rec.attribute9               := l_xiimb_rec(i).attribute9;
      l_iimb_rec.attribute10              := l_xiimb_rec(i).attribute10;
      l_iimb_rec.attribute11              := l_xiimb_rec(i).attribute11;
      l_iimb_rec.attribute12              := l_xiimb_rec(i).attribute12;
      l_iimb_rec.attribute13              := l_xiimb_rec(i).attribute13;
      l_iimb_rec.attribute14              := l_xiimb_rec(i).attribute14;
      l_iimb_rec.attribute15              := l_xiimb_rec(i).attribute15;
      l_iimb_rec.attribute16              := l_xiimb_rec(i).attribute16;
      l_iimb_rec.attribute17              := l_xiimb_rec(i).attribute17;
      l_iimb_rec.attribute18              := l_xiimb_rec(i).attribute18;
      l_iimb_rec.attribute19              := l_xiimb_rec(i).attribute19;
      l_iimb_rec.attribute20              := l_xiimb_rec(i).attribute20;
      l_iimb_rec.attribute21              := l_xiimb_rec(i).attribute21;
      l_iimb_rec.attribute22              := l_xiimb_rec(i).attribute22;
      l_iimb_rec.attribute23              := l_xiimb_rec(i).attribute23;
      l_iimb_rec.attribute24              := l_xiimb_rec(i).attribute24;
      l_iimb_rec.attribute25              := l_xiimb_rec(i).attribute25;
      l_iimb_rec.attribute26              := l_xiimb_rec(i).attribute26;
      l_iimb_rec.attribute27              := l_xiimb_rec(i).attribute27;
      l_iimb_rec.attribute28              := l_xiimb_rec(i).attribute28;
      l_iimb_rec.attribute29              := l_xiimb_rec(i).attribute29;
      l_iimb_rec.attribute30              := l_xiimb_rec(i).attribute30;
      l_iimb_rec.attribute_category       := l_xiimb_rec(i).attribute_category;
      l_iimb_rec.item_abccode             := l_xiimb_rec(i).item_abccode;
      l_iimb_rec.ont_pricing_qty_source   := l_xiimb_rec(i).ont_pricing_qty_source;
      l_iimb_rec.alloc_category_id        := l_xiimb_rec(i).alloc_category_id;
      l_iimb_rec.customs_category_id      := l_xiimb_rec(i).customs_category_id;
      l_iimb_rec.frt_category_id          := l_xiimb_rec(i).frt_category_id;
      l_iimb_rec.gl_category_id           := l_xiimb_rec(i).gl_category_id;
      l_iimb_rec.inv_category_id          := l_xiimb_rec(i).inv_category_id;
      l_iimb_rec.cost_category_id         := l_xiimb_rec(i).cost_category_id;
      l_iimb_rec.planning_category_id     := l_xiimb_rec(i).planning_category_id;
      l_iimb_rec.price_category_id        := l_xiimb_rec(i).price_category_id;
      l_iimb_rec.purch_category_id        := l_xiimb_rec(i).purch_category_id;
      l_iimb_rec.sales_category_id        := l_xiimb_rec(i).sales_category_id;
      l_iimb_rec.seq_category_id          := l_xiimb_rec(i).seq_category_id;
      l_iimb_rec.ship_category_id         := l_xiimb_rec(i).ship_category_id;
      l_iimb_rec.storage_category_id      := l_xiimb_rec(i).storage_category_id;
      l_iimb_rec.tax_category_id          := l_xiimb_rec(i).tax_category_id;
      l_iimb_rec.autolot_active_indicator := l_xiimb_rec(i).autolot_active_indicator;
      l_iimb_rec.lot_prefix               := l_xiimb_rec(i).lot_prefix;
      l_iimb_rec.lot_suffix               := l_xiimb_rec(i).lot_suffix;
      l_iimb_rec.sublot_prefix            := l_xiimb_rec(i).sublot_prefix;
      l_iimb_rec.sublot_suffix            := l_xiimb_rec(i).sublot_suffix;
      l_iimb_rec.creation_date            := l_xiimb_rec(i).creation_date;
      l_iimb_rec.created_by               := l_xiimb_rec(i).created_by;
      l_iimb_rec.last_update_date         := l_xiimb_rec(i).last_update_date;
      l_iimb_rec.last_updated_by          := l_xiimb_rec(i).last_updated_by;
      l_iimb_rec.last_update_login        := l_xiimb_rec(i).last_update_login;
      l_iimb_rec.program_application_id   := l_xiimb_rec(i).program_application_id;
      l_iimb_rec.program_id               := l_xiimb_rec(i).program_id;
      l_iimb_rec.program_update_date      := l_xiimb_rec(i).program_update_date;
      l_iimb_rec.request_id               := l_xiimb_rec(i).request_id;
--
      -- ===============================
      -- �o�^�̏ꍇ
      -- ===============================
      IF ( l_xiimb_rec(i).record_type = 'I' ) THEN
        xxcmm_004common_pkg.ins_opm_item(
          i_opm_item_rec => l_iimb_rec
         ,ov_errbuf      => lv_errbuf
         ,ov_retcode     => lv_retcode
         ,ov_errmsg      => lv_errmsg
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃ}�X�^�o�^�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xiimb_rec(i).item_no;
          RAISE global_api_expt;
        END IF;
        -- �o�^�����J�E���g
        gn_iimb_i_cnt := gn_iimb_i_cnt + 1;
      -- ===============================
      -- �X�V�̏ꍇ
      -- ===============================
      ELSE
        xxcmm_004common_pkg.upd_opm_item(
          i_opm_item_rec => l_iimb_rec
         ,ov_errbuf      => lv_errbuf
         ,ov_retcode     => lv_retcode
         ,ov_errmsg      => lv_errmsg
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃ}�X�^�X�V�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xiimb_rec(i).item_no;
          RAISE global_api_expt;
        END IF;
        -- �X�V�����J�E���g
        gn_iimb_u_cnt := gn_iimb_u_cnt + 1;
      END IF;
    END LOOP xiimb_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_iimb;
--
  /**********************************************************************************
   * Procedure Name   : proc_ximb
   * Description      : OPM�i�ڃA�h�I���o�^�E�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE proc_ximb(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ximb';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id         xxcmn_item_mst_b.item_id%TYPE;        -- �i��ID�i�[�p
    lt_parent_item_id  xxcmn_item_mst_b.parent_item_id%TYPE; -- �e�i��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xximb_cur IS
      SELECT
        xximb.*
      FROM
        xxccp_xcmn_item_mst_b xximb
      ORDER BY
        xximb.item_no
    ;
    TYPE l_xximb_ttype IS TABLE OF xxccp_xcmn_item_mst_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xximb_rec l_xximb_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xximb_cur;
    FETCH l_xximb_cur BULK COLLECT INTO l_xximb_rec;
    CLOSE l_xximb_cur;
--
    << xximb_loop >>
    FOR i IN 1..l_xximb_rec.COUNT LOOP
      -- ===============================
      -- �i��ID�擾
      -- ===============================
      BEGIN
        -- OPM�i�ڃ}�X�^����i��ID�擾
        SELECT iimb.item_id AS item_id
        INTO   lt_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xximb_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xximb_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- �e�i��ID�擾
      -- ===============================
      BEGIN
        -- OPM�i�ڃ}�X�^����e�i��ID�擾
        SELECT iimb.item_id AS parent_item_id
        INTO   lt_parent_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xximb_rec(i).parent_item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�e�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�e�i�ڃR�[�h��'||l_xximb_rec(i).parent_item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- �������R�[�h�폜
      -- ===============================
      IF ( l_xximb_rec(i).record_type = 'U' ) THEN
        BEGIN
          DELETE
          FROM   xxcmn_item_mst_b ximb
          WHERE  ximb.item_id           = lt_item_id
            AND  ximb.start_date_active = l_xximb_rec(i).start_date_active
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := 'OPM�i�ڃA�h�I���폜�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xximb_rec(i).item_no;
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ===============================
      -- OPM�i�ڃA�h�I���}�X�^�o�^
      -- ===============================
      BEGIN
        INSERT INTO xxcmn_item_mst_b(
          item_id
         ,start_date_active
         ,end_date_active
         ,active_flag
         ,item_name
         ,item_short_name
         ,item_name_alt
         ,parent_item_id
         ,obsolete_class
         ,obsolete_date
         ,model_type
         ,product_class
         ,product_type
         ,expiration_day
         ,delivery_lead_time
         ,whse_county_code
         ,standard_yield
         ,shipping_end_date
         ,rate_class
         ,shelf_life
         ,shelf_life_class
         ,bottle_class
         ,uom_class
         ,inventory_chk_class
         ,trace_class
         ,shipping_cs_unit_qty
         ,palette_max_cs_qty
         ,palette_max_step_qty
         ,palette_step_qty
         ,cs_weigth_or_capacity
         ,raw_material_consumption
         ,attribute1
         ,attribute2
         ,attribute3
         ,attribute4
         ,attribute5
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          lt_item_id                               -- �i��ID
         ,l_xximb_rec(i).start_date_active         -- �K�p�J�n��
         ,l_xximb_rec(i).end_date_active           -- �K�p�I����
         ,l_xximb_rec(i).active_flag               -- �K�p�σt���O
         ,l_xximb_rec(i).item_name                 -- ������
         ,l_xximb_rec(i).item_short_name           -- ����
         ,l_xximb_rec(i).item_name_alt             -- �J�i��
         ,lt_parent_item_id                        -- �e�i��ID
         ,l_xximb_rec(i).obsolete_class            -- �p�~�敪
         ,l_xximb_rec(i).obsolete_date             -- �p�~���i�������~���j
         ,l_xximb_rec(i).model_type                -- �^���
         ,l_xximb_rec(i).product_class             -- ���i����
         ,l_xximb_rec(i).product_type              -- ���i���
         ,l_xximb_rec(i).expiration_day            -- �ܖ�����
         ,l_xximb_rec(i).delivery_lead_time        -- �[������
         ,l_xximb_rec(i).whse_county_code          -- �H��Q�R�[�h
         ,l_xximb_rec(i).standard_yield            -- �W������
         ,l_xximb_rec(i).shipping_end_date         -- �o�ג�~��
         ,l_xximb_rec(i).rate_class                -- ���敪
         ,l_xximb_rec(i).shelf_life                -- �������
         ,l_xximb_rec(i).shelf_life_class          -- �ܖ����ԋ敪
         ,l_xximb_rec(i).bottle_class              -- �e��敪
         ,l_xximb_rec(i).uom_class                 -- �P�ʋ敪
         ,l_xximb_rec(i).inventory_chk_class       -- �I���敪
         ,l_xximb_rec(i).trace_class               -- �g���[�X�敪
         ,l_xximb_rec(i).shipping_cs_unit_qty      -- �o�ד���
         ,l_xximb_rec(i).palette_max_cs_qty        -- �z��
         ,l_xximb_rec(i).palette_max_step_qty      -- �p���b�g����ő�i��
         ,l_xximb_rec(i).palette_step_qty          -- �p���b�g�i
         ,l_xximb_rec(i).cs_weigth_or_capacity     -- �P�[�X�d�ʗe��
         ,l_xximb_rec(i).raw_material_consumption  -- �����g�p��
         ,l_xximb_rec(i).attribute1                -- �\���P
         ,l_xximb_rec(i).attribute2                -- �\���Q
         ,l_xximb_rec(i).attribute3                -- �\���R
         ,l_xximb_rec(i).attribute4                -- �\���S
         ,l_xximb_rec(i).attribute5                -- �\���T
         ,l_xximb_rec(i).created_by                -- �쐬��
         ,l_xximb_rec(i).creation_date             -- �쐬��
         ,l_xximb_rec(i).last_updated_by           -- �ŏI�X�V��
         ,l_xximb_rec(i).last_update_date          -- �ŏI�X�V��
         ,l_xximb_rec(i).last_update_login         -- �ŏI�X�V���O�C��
         ,l_xximb_rec(i).request_id                -- �v��ID
         ,l_xximb_rec(i).program_application_id    -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,l_xximb_rec(i).program_id                -- �R���J�����g�E�v���O����ID
         ,l_xximb_rec(i).program_update_date       -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := 'OPM�i�ڃA�h�I���}�X�^�o�^�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xximb_rec(i).item_no;
          RAISE global_api_others_expt;
      END;
      --
      IF ( l_xximb_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_ximb_i_cnt := gn_ximb_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_ximb_u_cnt := gn_ximb_u_cnt + 1;
      END IF;
    END LOOP xximb_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ximb;
--
  /**********************************************************************************
   * Procedure Name   : proc_ccd
   * Description      : OPM�i�ڌ����o�^�E�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE proc_ccd(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ccd';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id              cm_cmpt_dtl.item_id%TYPE;                -- �i��ID�i�[�p
    lt_cost_cmpntcls_code   cm_cmpt_mst_vl.cost_cmpntcls_code%TYPE;  -- �R���|�[�l���g�R�[�h�i�[�p
    lt_cost_cmpntcls_desc   cm_cmpt_mst_vl.cost_cmpntcls_desc%TYPE;  -- �R���|�[�l���g���̊i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xccd_cur IS
      SELECT
        xccd.*
      FROM
        xxccp_cm_cmpt_dtl xccd
      ORDER BY
        xccd.item_no
      , xccd.calendar_code
      , xccd.cost_cmpntcls_id
    ;
    TYPE l_xccd_ttype IS TABLE OF xxccp_cm_cmpt_dtl%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xccd_rec l_xccd_ttype;
--
    -- *** ���[�J���E���R�[�h ***
    l_opm_cost_header_rec     xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab       xxcmm_004common_pkg.opm_cost_dist_ttype;
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xccd_cur;
    FETCH l_xccd_cur BULK COLLECT INTO l_xccd_rec;
    CLOSE l_xccd_cur;
--
    << xccd_loop >>
    FOR i IN 1..l_xccd_rec.COUNT LOOP
      -- ===============================
      -- �����R���|�[�l���g�R�[�h�擾
      -- ===============================
      -- �p�t�H�[�}���X���������߂����Ŏ擾
      -- �{�Ԋ��Ŏ擾�s�̏ꍇ���Ȃ����߃G���[�n���h�����O�Ȃ�
      SELECT ccmv.cost_cmpntcls_code AS cost_cmpntcls_code
            ,ccmv.cost_cmpntcls_desc AS cost_cmpntcls_desc
      INTO   lt_cost_cmpntcls_code
            ,lt_cost_cmpntcls_desc
      FROM   cm_cmpt_mst_vl@t4_hon ccmv
      WHERE  ccmv.cost_cmpntcls_id = l_xccd_rec(i).cost_cmpntcls_id
      ;
--
      -- ===============================
      -- �i��ID�擾
      -- ===============================
      BEGIN
        -- OPM�i�ڃ}�X�^����i��ID�擾
        SELECT iimb.item_id AS item_id
        INTO   lt_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xccd_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xccd_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- OPM�����w�b�_�l�Z�b�g
      -- ===============================
      l_opm_cost_header_rec.calendar_code        := l_xccd_rec(i).calendar_code;
      l_opm_cost_header_rec.period_code          := l_xccd_rec(i).period_code;
      l_opm_cost_header_rec.item_id              := lt_item_id;
      --
      -- ===============================
      -- OPM�������גl���Z�b�g
      -- ===============================
      l_opm_cost_dist_tab(1).cost_cmpntcls_id    := l_xccd_rec(i).cost_cmpntcls_id;
      l_opm_cost_dist_tab(1).cmpnt_cost          := l_xccd_rec(i).cmpnt_cost;
--
      -- ===============================
      -- XXCMM���ʊ֐����R�[��
      -- ===============================
      xxcmm_004common_pkg.proc_opmcost_ref(
        i_cost_header_rec   => l_opm_cost_header_rec   -- OPM�����w�b�_���R�[�h�^�C�v
       ,i_cost_dist_tab     => l_opm_cost_dist_tab     -- OPM�������׃e�[�u���^�C�v
       ,ov_errbuf           => lv_errbuf               -- �G���[�E���b�Z�[�W
       ,ov_retcode          => lv_retcode              -- ���^�[���E�R�[�h
       ,ov_errmsg           => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := 'OPM�i�ڌ����̓o�^�E�X�V�Ɏ��s���܂����B'
                   ||'�i�ڃR�[�h��'    ||l_xccd_rec(i).item_no||'�A'
                   ||'�J�����_��'      ||l_xccd_rec(i).calendar_code||'�A'
                   ||'�R���|�[�l���g��'||lt_cost_cmpntcls_desc;
        --���ʊ֐�����G���[�E���b�Z�[�W���Ԃ��Ă��Ȃ��̂ł��̂܂ܐݒ�
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      IF ( l_xccd_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_ccd_i_cnt := gn_ccd_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_ccd_u_cnt := gn_ccd_u_cnt + 1;
      END IF;
    --
    END LOOP xccd_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ccd;
--
  /**********************************************************************************
   * Procedure Name   : proc_gic
   * Description      : OPM�i�ڃJ�e�S�������o�^�E�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE proc_gic(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_gic';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id              gmi_item_categories.item_id%TYPE;         -- �i��ID�i�[�p
    lt_category_set_id      gmi_item_categories.category_set_id%TYPE; -- �J�e�S���E�Z�b�gID�i�[�p
    lt_category_id          gmi_item_categories.category_id%TYPE;     -- �J�e�S��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xgic_cur IS
      SELECT
        xgic.*
      FROM
        xxccp_gmi_item_categories xgic
      ORDER BY
        xgic.item_no
      , xgic.category_set_id
      , xgic.category_id
    ;
    TYPE l_xgic_ttype IS TABLE OF xxccp_gmi_item_categories%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xgic_rec l_xgic_ttype;
--
    -- *** ���[�J���E���R�[�h ***
    l_item_category_rec     xxcmm_004common_pkg.opmitem_category_rtype;
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xgic_cur;
    FETCH l_xgic_cur BULK COLLECT INTO l_xgic_rec;
    CLOSE l_xgic_cur;
--
    << xgic_loop >>
    FOR i IN 1..l_xgic_rec.COUNT LOOP
--
      -- ===============================
      -- �i��ID�擾
      -- ===============================
      BEGIN
        -- OPM�i�ڃ}�X�^����i��ID�擾
        SELECT iimb.item_id AS item_id
        INTO   lt_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xgic_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xgic_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- �J�e�S���E�Z�b�gID�A�J�e�S��ID�擾
      -- ===============================
      BEGIN
        SELECT mcs.category_set_id AS category_set_id
              ,mc.category_id      AS category_id
        INTO   lt_category_set_id
              ,lt_category_id
        FROM   mtl_category_sets mcs
              ,mtl_categories    mc
        WHERE  mc.structure_id = mcs.structure_id
          AND  mcs.category_set_name = l_xgic_rec(i).category_set_name
          AND  mc.segment1           = l_xgic_rec(i).segment1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�J�e�S���E�Z�b�gID�A�J�e�S��ID�̎擾�Ɏ��s���܂����B'
                     ||'�J�e�S���E�Z�b�g��'||l_xgic_rec(i).category_set_name||'�A'
                     ||'�J�e�S����'        ||l_xgic_rec(i).segment1;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ���R�[�h�Z�b�g
      l_item_category_rec := NULL;
      l_item_category_rec.item_id         := lt_item_id;
      l_item_category_rec.category_set_id := lt_category_set_id;
      l_item_category_rec.category_id     := lt_category_id;
--
      -- ===============================
      -- �o�^�A�X�V�̏ꍇ
      -- ===============================
      IF ( l_xgic_rec(i).record_type IN ('I','U') ) THEN
        -- OPM�i�ڃJ�e�S�������o�^�E�X�V����
        xxcmm_004common_pkg.proc_opmitem_categ_ref(
          i_item_category_rec => l_item_category_rec
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errbuf := lv_errmsg;
          lv_errmsg := 'OPM�i�ڃJ�e�S�������o�^�E�X�V�Ɏ��s���܂����B'
                      ||'�J�e�S���E�Z�b�g��'||l_xgic_rec(i).category_set_name||'�A'
                      ||'�J�e�S����'        ||l_xgic_rec(i).segment1         ||'�A'
                      ||'�i�ڃR�[�h��'      ||l_xgic_rec(i).item_no;
          RAISE global_api_expt;
        END IF;
        --
        IF ( l_xgic_rec(i).record_type = 'I' ) THEN
          -- �o�^�����J�E���g
          gn_gic_i_cnt := gn_gic_i_cnt + 1;
        ELSE
          -- �X�V�����J�E���g
          gn_gic_u_cnt := gn_gic_u_cnt + 1;
        END IF;
      END IF;
--
    END LOOP xgic_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_gic;
--
  /**********************************************************************************
   * Procedure Name   : proc_msib
   * Description      : DISC�i�ڃ}�X�^�o�^�E�X�V(A-8)
   ***********************************************************************************/
  PROCEDURE proc_msib(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_msib';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_request_id             NUMBER;         -- �v��ID
    lb_ret                    BOOLEAN;
    lv_phase                  VARCHAR2(100);  -- �v���t�F�[�Y
    lv_status                 VARCHAR2(100);  -- �v���X�e�[�^�X
    lv_dev_phase              VARCHAR2(100);  -- �v���t�F�[�Y�R�[�h
    lv_dev_status             VARCHAR2(100);  -- �v���X�e�[�^�X�R�[�h
    lv_message                VARCHAR2(2000); -- �������b�Z�[�W
    --
    lt_inventory_item_id      mtl_system_items_interface.inventory_item_id%TYPE;  -- �g�D�i��ID�i�[�p
    lt_reservable_type        mtl_system_items_interface.reservable_type%TYPE;    -- �\��\�i�[�p
    lt_transaction_type       mtl_system_items_interface.transaction_type%TYPE;   -- ����^�C�v�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �}�X�^�g�D(ZZZ)
    CURSOR l_xmsib_zzz_cur IS
      SELECT
        xmsib.*
      FROM
        xxccp_mtl_system_items_b xmsib
      WHERE xmsib.organization_code = 'ZZZ'
      ORDER BY
        xmsib.segment1
    ;
    TYPE l_xmsib_zzz_ttype IS TABLE OF xxccp_mtl_system_items_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xmsib_zzz_rec l_xmsib_zzz_ttype;
--
    -- �c�Ƒg�D(Z99)
    CURSOR l_xmsib_z99_cur IS
      SELECT
        xmsib.*
      FROM
        xxccp_mtl_system_items_b xmsib
      WHERE xmsib.organization_code = 'Z99'
      ORDER BY
        xmsib.segment1
    ;
    TYPE l_xmsib_z99_ttype IS TABLE OF xxccp_mtl_system_items_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xmsib_z99_rec l_xmsib_z99_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �}�X�^�g�D(ZZZ)
    -- ===============================
    --�J�[�\���I�[�v��
    OPEN l_xmsib_zzz_cur;
    FETCH l_xmsib_zzz_cur BULK COLLECT INTO l_xmsib_zzz_rec;
    CLOSE l_xmsib_zzz_cur;
--
    << xmsib_zzz_loop >>
    FOR i IN 1..l_xmsib_zzz_rec.COUNT LOOP
      -- ===============================
      -- OPM�i�ڃg���K�[�N���R���J�����g���s
      -- ===============================
      ln_request_id := fnd_request.submit_request(
        application   => 'XXCMN'
       ,program       => 'XXCMN810003C'               -- OPM�i�ڃg���K�[�N���R���J�����g
       ,description   => NULL
       ,start_time    => NULL
       ,sub_request   => FALSE
       ,argument1     => l_xmsib_zzz_rec(i).segment1  -- �i�ڃR�[�h
      );
--
      --�R���J�����g�N���`�F�b�N
      IF ( ln_request_id <= 0 ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := 'OPM�i�ڃg���K�[�N���R���J�����g���s�Ɏ��s���܂����B'
                    ||'�i�ڃR�[�h��'||l_xmsib_zzz_rec(i).segment1;
        lv_errbuf := lv_errmsg;
        ROLLBACK;
        RAISE global_api_expt;
      END IF;
      --
      IF ( l_xmsib_zzz_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_msib_i_cnt := gn_msib_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_msib_u_cnt := gn_msib_u_cnt + 1;
      END IF;
--
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      -- ===============================
      -- �R���J�����g�I���ҋ@
      -- ===============================
      lb_ret := fnd_concurrent.wait_for_request(
        request_id    => ln_request_id      -- �v��ID
       ,interval      => 5                  -- �Ď��Ԋu
       ,max_wait      => 0                  -- �R���J�����g�Ď��ő厞��
       ,phase         => lv_phase           -- �t�F�[�Y
       ,status        => lv_status          -- �X�e�[�^�X
       ,dev_phase     => lv_dev_phase       -- �t�F�[�Y
       ,dev_status    => lv_dev_status      -- �X�e�[�^�X
       ,message       => lv_message         -- �������b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�R���J�����g�ҋ@�Ɏ��s���܂����B'
                   ||'�v��ID��'||ln_request_id;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    --
    END LOOP xmsib_zzz_loop;
--
    -- ===============================
    -- �c�Ƒg�D(Z99)
    -- ===============================
    --�J�[�\���I�[�v��
    OPEN l_xmsib_z99_cur;
    FETCH l_xmsib_z99_cur BULK COLLECT INTO l_xmsib_z99_rec;
    CLOSE l_xmsib_z99_cur;
--
    << xmsib_z99_loop >>
    FOR i IN 1..l_xmsib_z99_rec.COUNT LOOP
      -- ===============================
      -- �g�D�i��ID�A�\��\�擾
      -- ===============================
      BEGIN
        -- �g�D�i��ID�A�\��\�擾
        -- �}�X�^�[/�q�R���t���N�g���������邽�߁A�}�X�^�g�D�́u�\��\�v���擾
        SELECT msib.inventory_item_id AS inventory_item_id
              ,msib.reservable_type   AS reservable_type
        INTO   lt_inventory_item_id
              ,lt_reservable_type
        FROM   mtl_system_items_b msib
        WHERE  msib.organization_id = gt_mst_org_id_t4
          AND  msib.segment1        = l_xmsib_z99_rec(i).segment1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�g�D�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xmsib_z99_rec(i).segment1;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      --
      -- ===============================
      -- ����^�C�v�Z�b�g
      -- ===============================
      IF ( l_xmsib_z99_rec(i).record_type = 'I' ) THEN
        lt_transaction_type := 'CREATE';
      ELSE
        lt_transaction_type := 'UPDATE';
      END IF;
      --
      -- ===============================
      -- �i��OIF�o�^
      -- ===============================
      BEGIN
        INSERT INTO mtl_system_items_interface(
          inventory_item_id             -- Disc�i��ID
         ,organization_id               -- �g�D�iZ99�j
         ,purchasing_item_flag          -- �w���i��
         ,shippable_item_flag           -- �o�׉\
         ,customer_order_flag           -- �ڋq��
         ,purchasing_enabled_flag       -- �w���\
         ,customer_order_enabled_flag   -- �ڋq�󒍉\
         ,internal_order_enabled_flag   -- �Г�����
         ,so_transactions_flag          -- OE ����\
         ,mtl_transactions_enabled_flag -- ����\
         ,reservable_type               -- �\��\
         ,returnable_flag               -- �ԕi�\
         ,stock_enabled_flag            -- �݌ɕۗL�\
         ,lot_control_code              -- ���b�g�Ǘ�
         ,location_control_code         -- �ۊǒI�Ǘ�
         ,process_flag                  -- �v���Z�X�t���O
         ,transaction_type              -- �����^�C�v
         ,description
         ,unit_of_issue
         ,primary_uom_code
         ,primary_unit_of_measure
         ,summary_flag
         ,enabled_flag
        ) VALUES (
          lt_inventory_item_id
         ,gt_org_id_t4
         ,l_xmsib_z99_rec(i).purchasing_item_flag
         ,l_xmsib_z99_rec(i).shippable_item_flag
         ,l_xmsib_z99_rec(i).customer_order_flag
         ,l_xmsib_z99_rec(i).purchasing_enabled_flag
         ,l_xmsib_z99_rec(i).customer_order_enabled_flag
         ,l_xmsib_z99_rec(i).internal_order_enabled_flag
         ,l_xmsib_z99_rec(i).so_transactions_flag
         ,l_xmsib_z99_rec(i).mtl_transactions_enabled_flag
         ,lt_reservable_type
         ,l_xmsib_z99_rec(i).returnable_flag
         ,l_xmsib_z99_rec(i).stock_enabled_flag
         ,1
         ,l_xmsib_z99_rec(i).location_control_code
         ,1
         ,lt_transaction_type
         ,l_xmsib_z99_rec(i).description
         ,l_xmsib_z99_rec(i).unit_of_issue
         ,l_xmsib_z99_rec(i).primary_uom_code
         ,l_xmsib_z99_rec(i).primary_unit_of_measure
         ,l_xmsib_z99_rec(i).summary_flag
         ,l_xmsib_z99_rec(i).enabled_flag
        );
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg :=  '�i��OIF�o�^�Ɏ��s���܂����B'
                      ||'�i�ڃR�[�h��'||l_xmsib_z99_rec(i).segment1;
          RAISE global_api_others_expt;
      END;
      --
      IF ( l_xmsib_z99_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_msib_i_cnt := gn_msib_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_msib_u_cnt := gn_msib_u_cnt + 1;
      END IF;
--
    END LOOP xmsib_z99_loop;
--
    -- �o�^���R�[�h�����݂���ꍇ
    IF ( gn_msib_i_cnt > 0 ) THEN
      -- ===============================
      -- �i�ڂ̃C���|�[�g(�V�K�i��)���s
      -- ===============================
      ln_request_id := fnd_request.submit_request(
        application   => 'INV'
       ,program       => 'INCOIN'
       ,description   => NULL
       ,start_time    => NULL
       ,sub_request   => FALSE
       ,argument1     => gt_org_id_t4  -- �g�DID
       ,argument2     => 1             -- �S�g�D
       ,argument3     => 1             -- �i�ڂ̌���
       ,argument4     => 1             -- �i�ڏ���
       ,argument5     => 1             -- �����ύs�̍폜
       ,argument6     => NULL          -- ���������i�ڃZ�b�g
       ,argument7     => 1             -- 1:�V�K�i�ڂ̍쐬
       ,argument8     => 1             -- �������̃��R�[�h����50�𒴂���ꍇ�ɓ��v�̎��W�����s
      );
--
      --�R���J�����g�N���`�F�b�N
      IF ( ln_request_id <= 0 ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�i�ڂ̃C���|�[�g(�V�K�i��)���s�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        ROLLBACK;
        RAISE global_api_expt;
      END IF;
--
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      -- �R���J�����g�I���ҋ@
      lb_ret := fnd_concurrent.wait_for_request(
        request_id    => ln_request_id      -- �v��ID
       ,interval      => 5                  -- �Ď��Ԋu
       ,max_wait      => 0                  -- �R���J�����g�Ď��ő厞��
       ,phase         => lv_phase           -- �t�F�[�Y
       ,status        => lv_status          -- �X�e�[�^�X
       ,dev_phase     => lv_dev_phase       -- �t�F�[�Y
       ,dev_status    => lv_dev_status      -- �X�e�[�^�X
       ,message       => lv_message         -- �������b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�R���J�����g�ҋ@�Ɏ��s���܂����B'
                   ||'�v��ID��'||ln_request_id;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �X�V���R�[�h�����݂���ꍇ
    IF ( gn_msib_u_cnt > 0 ) THEN
      -- ===============================
      -- �i�ڂ̃C���|�[�g(�����i��)
      -- ===============================
      ln_request_id := fnd_request.submit_request(
        application   => 'INV'
       ,program       => 'INCOIN'
       ,description   => NULL
       ,start_time    => NULL
       ,sub_request   => FALSE
       ,argument1     => gt_org_id_t4  -- �g�DID
       ,argument2     => 1             -- �S�g�D
       ,argument3     => 1             -- �i�ڂ̌���
       ,argument4     => 1             -- �i�ڏ���
       ,argument5     => 1             -- �����ύs�̍폜
       ,argument6     => NULL          -- ���������i�ڃZ�b�g
       ,argument7     => 2             -- 2:�����i�ڂ̍X�V
       ,argument8     => 1             -- �������̃��R�[�h����50�𒴂���ꍇ�ɓ��v�̎��W�����s
      );
--
      --�R���J�����g�N���`�F�b�N
      IF ( ln_request_id <= 0 ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�i�ڂ̃C���|�[�g(�����i��)���s�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        ROLLBACK;
        RAISE global_api_expt;
      END IF;
--
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      -- �R���J�����g�I���ҋ@
      lb_ret := fnd_concurrent.wait_for_request(
        request_id    => ln_request_id      -- �v��ID
       ,interval      => 5                  -- �Ď��Ԋu
       ,max_wait      => 0                  -- �R���J�����g�Ď��ő厞��
       ,phase         => lv_phase           -- �t�F�[�Y
       ,status        => lv_status          -- �X�e�[�^�X
       ,dev_phase     => lv_dev_phase       -- �t�F�[�Y
       ,dev_status    => lv_dev_status      -- �X�e�[�^�X
       ,message       => lv_message         -- �������b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
         --�G���[���b�Z�[�W�o��
        lv_errmsg := '�R���J�����g�ҋ@�Ɏ��s���܂����B'
                   ||'�v��ID��'||ln_request_id;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_msib;
---
  /**********************************************************************************
   * Procedure Name   : proc_xsib
   * Description      : DISC�i�ڃA�h�I���o�^�E�X�V(A-9)
   ***********************************************************************************/
  PROCEDURE proc_xsib(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xsib';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id         xxcmm_system_items_b.item_id%TYPE;     -- �i��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xxsib_cur IS
      SELECT
        xxsib.*
      FROM
        xxccp_xcmm_system_items_b xxsib
      ORDER BY
        xxsib.item_code
    ;
    TYPE l_xxsib_ttype IS TABLE OF xxccp_xcmm_system_items_b%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xxsib_rec l_xxsib_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xxsib_cur;
    FETCH l_xxsib_cur BULK COLLECT INTO l_xxsib_rec;
    CLOSE l_xxsib_cur;
--
    << xxsib_loop >>
    FOR i IN 1..l_xxsib_rec.COUNT LOOP
      -- ===============================
      -- LOOKUP�\�L���`�F�b�N
      -- ===============================
      --�e��Q�R�[�h
      IF ( l_xxsib_rec(i).vessel_group IS NOT NULL ) THEN
        chk_exists_lkp(
          iv_lookup_type  => 'XXCMM_ITM_YOKIGUN'
         ,iv_lookup_code  => l_xxsib_rec(i).vessel_group
         ,iv_key_info     => l_xxsib_rec(i).item_code
         ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
      --
      --�o���Q�R�[�h
      IF ( l_xxsib_rec(i).acnt_group IS NOT NULL ) THEN
        chk_exists_lkp(
          iv_lookup_type  => 'XXCMM_ITM_KERIGUN'
         ,iv_lookup_code  => l_xxsib_rec(i).acnt_group
         ,iv_key_info     => l_xxsib_rec(i).item_code
         ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
      --
      --�o���e��Q�R�[�h
      IF ( l_xxsib_rec(i).acnt_vessel_group IS NOT NULL ) THEN
        chk_exists_lkp(
          iv_lookup_type  => 'XXCMM_ITM_KERIYOKIGUN'
         ,iv_lookup_code  => l_xxsib_rec(i).acnt_vessel_group
         ,iv_key_info     => l_xxsib_rec(i).item_code
         ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
      --
      --�u�����h�Q�R�[�h
      IF ( l_xxsib_rec(i).brand_group IS NOT NULL ) THEN
        chk_exists_lkp(
          iv_lookup_type  => 'XXCMM_ITM_BRANDGUN'
         ,iv_lookup_code  => l_xxsib_rec(i).brand_group
         ,iv_key_info     => l_xxsib_rec(i).item_code
         ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
      --
      --���X�d����
      IF ( l_xxsib_rec(i).sp_supplier_code IS NOT NULL ) THEN
        chk_exists_lkp(
          iv_lookup_type  => 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'
         ,iv_lookup_code  => l_xxsib_rec(i).sp_supplier_code
         ,iv_key_info     => l_xxsib_rec(i).item_code
         ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
--
      -- ===============================
      -- �i��ID�擾
      -- ===============================
      BEGIN
        -- OPM�i�ڃ}�X�^����i��ID�擾
        SELECT iimb.item_id AS item_id
        INTO   lt_item_id
        FROM   ic_item_mst_b iimb
        WHERE  iimb.item_no = l_xxsib_rec(i).item_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xxsib_rec(i).item_code;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- �������R�[�h�폜
      -- ===============================
      IF ( l_xxsib_rec(i).record_type = 'U' ) THEN
        BEGIN
          DELETE
          FROM   xxcmm_system_items_b xsib
          WHERE  xsib.item_id = lt_item_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := 'DISC�i�ڃA�h�I���폜�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xxsib_rec(i).item_code;
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ===============================
      -- DISC�i�ڃA�h�I���}�X�^�o�^
      -- ===============================
      BEGIN
        INSERT INTO xxcmm_system_items_b(
          item_id
         ,item_code
         ,tax_rate
         ,baracha_div
         ,nets
         ,nets_uom_code
         ,inc_num
         ,vessel_group
         ,acnt_group
         ,acnt_vessel_group
         ,brand_group
         ,sp_supplier_code
         ,case_jan_code
         ,new_item_div
         ,bowl_inc_num
         ,item_status_apply_date
         ,item_status
         ,renewal_item_code
         ,search_update_date
         ,case_conv_inc_num
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          lt_item_id                               -- �i��ID
         ,l_xxsib_rec(i).item_code                 -- �i�ڃR�[�h
         ,l_xxsib_rec(i).tax_rate                  -- ����ŗ�
         ,l_xxsib_rec(i).baracha_div               -- �o�����敪
         ,l_xxsib_rec(i).nets                      -- ���e��
         ,l_xxsib_rec(i).nets_uom_code             -- ���e�ʒP��
         ,l_xxsib_rec(i).inc_num                   -- �������
         ,l_xxsib_rec(i).vessel_group              -- �e��Q
         ,l_xxsib_rec(i).acnt_group                -- �o���Q
         ,l_xxsib_rec(i).acnt_vessel_group         -- �o���e��Q
         ,l_xxsib_rec(i).brand_group               -- �u�����h�Q
         ,l_xxsib_rec(i).sp_supplier_code          -- ���X�d����R�[�h
         ,l_xxsib_rec(i).case_jan_code             -- �P�[�XJAN�R�[�h
         ,l_xxsib_rec(i).new_item_div              -- �V���i�敪
         ,l_xxsib_rec(i).bowl_inc_num              -- �{�[������
         ,l_xxsib_rec(i).item_status_apply_date    -- �i�ڃX�e�[�^�X�K�p��
         ,l_xxsib_rec(i).item_status               -- �i�ڃX�e�[�^�X
         ,l_xxsib_rec(i).renewal_item_code         -- ���j���[�A�������i�R�[�h
         ,l_xxsib_rec(i).search_update_date        -- �����ΏۍX�V��
         ,l_xxsib_rec(i).case_conv_inc_num         -- �P�[�X���Z����
         ,l_xxsib_rec(i).created_by                -- �쐬��
         ,l_xxsib_rec(i).creation_date             -- �쐬��
         ,l_xxsib_rec(i).last_updated_by           -- �ŏI�X�V��
         ,l_xxsib_rec(i).last_update_date          -- �ŏI�X�V��
         ,l_xxsib_rec(i).last_update_login         -- �ŏI�X�V���O�C��
         ,l_xxsib_rec(i).request_id                -- �v��ID
         ,l_xxsib_rec(i).program_application_id    -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,l_xxsib_rec(i).program_id                -- �R���J�����g�E�v���O����ID
         ,l_xxsib_rec(i).program_update_date       -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   =>   'DISC�i�ڃA�h�I���o�^�Ɏ��s���܂����B'
                      ||'�i�ڃR�[�h��'||l_xxsib_rec(i).item_code
          );
          RAISE global_api_others_expt;
      END;
      --
      IF ( l_xxsib_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_xsib_i_cnt := gn_xsib_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_xsib_u_cnt := gn_xsib_u_cnt + 1;
      END IF;
    END LOOP xxsib_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_xsib;
--
  /**********************************************************************************
   * Procedure Name   : proc_xsibh
   * Description      : DISC�i�ڕύX�����A�h�I���o�^�E�X�V(A-10)
   ***********************************************************************************/
  PROCEDURE proc_xsibh(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xsibh';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_item_id         xxcmm_system_items_b_hst.item_id%TYPE;     -- �i��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xxsibh_cur IS
      SELECT
        xxsibh.*
      FROM
        xxccp_xcmm_system_items_b_hst xxsibh
      ORDER BY
        xxsibh.item_hst_id
    ;
    TYPE l_xxsibh_ttype IS TABLE OF xxccp_xcmm_system_items_b_hst%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xxsibh_rec l_xxsibh_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xxsibh_cur;
    FETCH l_xxsibh_cur BULK COLLECT INTO l_xxsibh_rec;
    CLOSE l_xxsibh_cur;
--
    << xxsibh_loop >>
    FOR i IN 1..l_xxsibh_rec.COUNT LOOP
      -- ===============================
      -- �������R�[�h�폜
      -- ===============================
      IF ( l_xxsibh_rec(i).record_type IN ('U','D') ) THEN
        BEGIN
          DELETE
          FROM   xxcmm_system_items_b_hst xsibh
          WHERE  xsibh.item_hst_id = l_xxsibh_rec(i).item_hst_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := 'DISC�i�ڕύX�����A�h�I���폜�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xxsibh_rec(i).item_code;
            RAISE global_api_others_expt;
        END;
        --
        IF ( l_xxsibh_rec(i).record_type = 'D' ) THEN
          -- �폜�����J�E���g
          gn_xsibh_d_cnt := gn_xsibh_d_cnt + 1;
        END IF;
      END IF;
--
      -- ===============================
      -- �o�^�A�X�V�̏ꍇ
      -- ===============================
      IF ( l_xxsibh_rec(i).record_type IN ('I','U') ) THEN
        -- ===============================
        -- �i��ID�擾
        -- ===============================
        BEGIN
          -- OPM�i�ڃ}�X�^����i��ID�擾
          SELECT iimb.item_id AS item_id
          INTO   lt_item_id
          FROM   ic_item_mst_b iimb
          WHERE  iimb.item_no = l_xxsibh_rec(i).item_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xxsibh_rec(i).item_code;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END;
--
        -- ===============================
        -- �i�ڕύX�����A�h�I���o�^
        -- ===============================
        BEGIN
          INSERT INTO xxcmm_system_items_b_hst(
            item_hst_id
           ,item_id
           ,item_code
           ,apply_date
           ,apply_flag
           ,item_status
           ,policy_group
           ,fixed_price
           ,discrete_cost
           ,first_apply_flag
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login
           ,request_id
           ,program_application_id
           ,program_id
           ,program_update_date
          ) VALUES (
            l_xxsibh_rec(i).item_hst_id              -- �i�ڕύX����ID
           ,lt_item_id                               -- �i��ID
           ,l_xxsibh_rec(i).item_code                -- �i�ڃR�[�h
           ,l_xxsibh_rec(i).apply_date               -- �K�p��
           ,l_xxsibh_rec(i).apply_flag               -- �K�p�t���O
           ,l_xxsibh_rec(i).item_status              -- �i�ڃX�e�[�^�X
           ,l_xxsibh_rec(i).policy_group             -- ����Q�R�[�h
           ,l_xxsibh_rec(i).fixed_price              -- �艿
           ,l_xxsibh_rec(i).discrete_cost            -- �c�ƌ���
           ,l_xxsibh_rec(i).first_apply_flag         -- ����K�p�t���O
           ,l_xxsibh_rec(i).created_by               -- �쐬��
           ,l_xxsibh_rec(i).creation_date            -- �쐬��
           ,l_xxsibh_rec(i).last_updated_by          -- �ŏI�X�V��
           ,l_xxsibh_rec(i).last_update_date         -- �ŏI�X�V��
           ,l_xxsibh_rec(i).last_update_login        -- �ŏI�X�V���O�C��
           ,l_xxsibh_rec(i).request_id               -- �v��ID
           ,l_xxsibh_rec(i).program_application_id   -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
           ,l_xxsibh_rec(i).program_id               -- �R���J�����g�E�v���O����ID
           ,l_xxsibh_rec(i).program_update_date      -- �v���O�����ɂ��X�V��
          );
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := 'DISC�i�ڕύX�����A�h�I���o�^�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xxsibh_rec(i).item_code;
            RAISE global_api_others_expt;
        END;
        --
        IF ( l_xxsibh_rec(i).record_type = 'I' ) THEN
          -- �o�^�����J�E���g
          gn_xsibh_i_cnt := gn_xsibh_i_cnt + 1;
        ELSE
          -- �X�V�����J�E���g
          gn_xsibh_u_cnt := gn_xsibh_u_cnt + 1;
        END IF;
      END IF;
    END LOOP xxsibh_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_xsibh;
--
  /**********************************************************************************
   * Procedure Name   : proc_cicd
   * Description      : DISC�i�ڌ����o�^�E�X�V(A-13)
   ***********************************************************************************/
  PROCEDURE proc_cicd(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cicd';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_request_id             NUMBER;         -- �v��ID
    lb_ret                    BOOLEAN;
    lv_phase                  VARCHAR2(100);  -- �v���t�F�[�Y
    lv_status                 VARCHAR2(100);  -- �v���X�e�[�^�X
    lv_dev_phase              VARCHAR2(100);  -- �v���t�F�[�Y�R�[�h
    lv_dev_status             VARCHAR2(100);  -- �v���X�e�[�^�X�R�[�h
    lv_message                VARCHAR2(2000); -- �������b�Z�[�W
    --
    lt_code_combination_id    gl_code_combinations.code_combination_id%TYPE;  -- ��������Ȗ�ID�i�[�p
    lt_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;      -- �g�D�i��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xcicd_cur IS
      SELECT
        xcicd.*
      FROM
        xxccp_cst_item_cost_details xcicd
      ORDER BY
        xcicd.item_no
    ;
    TYPE l_xcicd_ttype IS TABLE OF xxccp_cst_item_cost_details%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xcicd_rec l_xcicd_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ��������Ȗ�ID�擾
    -- ===============================
    BEGIN
      -- ����Ȗڑg�ݍ��킹�}�X�^���璲������Ȗ�ID�擾
      SELECT gcc.code_combination_id AS code_combination_id
      INTO   lt_code_combination_id
      FROM   gl_code_combinations gcc
      WHERE  gcc.segment1 = '001'        -- ������Јɓ���
        AND  gcc.segment2 = '9090'       -- ��������
        AND  gcc.segment3 = '82788'      -- ���㌴��(����)
        AND  gcc.segment4 = '00000'      -- ��`�Ȃ�
        AND  gcc.segment5 = '000000000'  -- ��`�Ȃ�
        AND  gcc.segment6 = '000000'     -- �̎�̋��I���� �g�p�֎~
        AND  gcc.segment7 = '0'          -- ��`�Ȃ�
        AND  gcc.segment8 = '0'          -- ��`�Ȃ�
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '��������Ȗ�ID�̎擾�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --�J�[�\���I�[�v��
    OPEN l_xcicd_cur;
    FETCH l_xcicd_cur BULK COLLECT INTO l_xcicd_rec;
    CLOSE l_xcicd_cur;
--
    << xcicd_loop >>
    FOR i IN 1..l_xcicd_rec.COUNT LOOP
      -- ===============================
      -- �g�D�i��ID�擾
      -- ===============================
      BEGIN
        -- DISC�i�ڃ}�X�^����g�D�i��ID�擾
        SELECT msib.inventory_item_id AS inventory_item_id
        INTO   lt_inventory_item_id
        FROM   mtl_system_items_b msib
        WHERE  msib.organization_id = gt_mst_org_id_t4
          AND  msib.segment1        = l_xcicd_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�g�D�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xcicd_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- ����OIF�o�^
      -- ===============================
      BEGIN
        INSERT INTO cst_item_cst_dtls_interface(
          inventory_item_id
         ,group_id
         ,organization_id
         ,usage_rate_or_amount
         ,resource_code
         ,cost_element
         ,process_flag
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          lt_inventory_item_id
         ,l_xcicd_rec(i).cost_type_id
         ,gt_org_id_t4
         ,l_xcicd_rec(i).usage_rate_or_amount
         ,'�c�ƌ���'                  -- �Œ�F'�c�ƌ���'
         ,'����'                      -- �Œ�F'����'
         ,1                           -- �Œ�F1
         ,cn_created_by               -- �쐬��
         ,cd_creation_date            -- �쐬��
         ,cn_last_updated_by          -- �ŏI�X�V��
         ,cd_last_update_date         -- �ŏI�X�V��
         ,cn_last_update_login        -- �ŏI�X�V���O�C��
         ,cn_request_id               -- �v��ID
         ,cn_program_application_id   -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,cn_program_id               -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date      -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '����OIF�o�^�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xcicd_rec(i).item_no;
          RAISE global_api_others_expt;
      END;
      --
      IF ( l_xcicd_rec(i).record_type = 'I' ) THEN
        -- �o�^�����J�E���g
        gn_cicd_i_cnt := gn_cicd_i_cnt + 1;
      ELSE
        -- �X�V�����J�E���g
        gn_cicd_u_cnt := gn_cicd_u_cnt + 1;
      END IF;
    END LOOP xcicd_loop;
--
    -- �o�^�E�X�V���R�[�h�����݂���ꍇ
    IF ( gn_cicd_i_cnt > 0 )
      OR ( gn_cicd_u_cnt > 0 ) THEN
      -- ===============================
      -- �����C���|�[�g����
      -- ===============================
      ln_request_id := fnd_request.submit_request(
        application   => 'BOM'
       ,program       => 'CSTPCIMP'
       ,description   => NULL
       ,start_time    => NULL
       ,sub_request   => FALSE
       ,argument1     => 1             -- �i�ڌ����C���|�[�g�E�I�v�V����
       ,argument2     => 2             -- ���Y���N�G�X�g���s���[�h
       ,argument3     => 1             -- ���Y�O���[�vID�I�v�V����
       ,argument4     => 1             -- �_�~�[�E�O���[�vID
       ,argument5     => 1000          -- ���s���铖�Y�O���[�vID
       ,argument6     => '�ۗ�����'    -- �C���|�[�g�p�����^�C�v
       ,argument7     => 1             -- ���������s���폜����
      );
--
      --�R���J�����g�N���`�F�b�N
      IF ( ln_request_id <= 0 ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�����C���|�[�g�������s�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        ROLLBACK;
        RAISE global_api_expt;
      END IF;
--
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      -- �R���J�����g�I���ҋ@
      lb_ret := fnd_concurrent.wait_for_request(
        request_id    => ln_request_id      -- �v��ID
       ,interval      => 5                  -- �Ď��Ԋu
       ,max_wait      => 0                  -- �R���J�����g�Ď��ő厞��
       ,phase         => lv_phase           -- �t�F�[�Y
       ,status        => lv_status          -- �X�e�[�^�X
       ,dev_phase     => lv_dev_phase       -- �t�F�[�Y
       ,dev_status    => lv_dev_status      -- �X�e�[�^�X
       ,message       => lv_message         -- �������b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
         --�G���[���b�Z�[�W�o��
        lv_errmsg := '�R���J�����g�ҋ@�Ɏ��s���܂����B'
                   ||'�v��ID��'||ln_request_id;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ===============================
      -- �W�������̍X�V
      -- ===============================
      ln_request_id := fnd_request.submit_request(
        application   => 'BOM'
       ,program       => 'CMCICU'
       ,description   => NULL
       ,start_time    => NULL
       ,sub_request   => FALSE
       ,argument1     => gt_org_id_t4            -- �g�DID
       ,argument2     => 0                       -- BOM�C���X�g�[���E�t���O
       ,argument3     => 1000                    -- �����^�C�v
       ,argument4     => lt_code_combination_id  -- �݌ɒ�������Ȗ�
       ,argument5     => '�ۗ��c�ƌ����̔��f'    -- �E�v
       ,argument6     => 1                       -- �i�ڔ͈�
       ,argument7     => 1                       -- �\�[�g�E�I�v�V����
       ,argument8     => 0                       -- �X�V�I�v�V����
       ,argument9     => NULL                    -- �i�ڃ_�~�[
       ,argument10    => NULL                    -- �J�e�S���E�_�~�[
       ,argument11    => NULL                    -- ����i��
       ,argument12    => NULL                    -- �J�e�S���E�Z�b�g
       ,argument13    => NULL                    -- �J�e�S�����؃t���O
       ,argument14    => NULL                    -- �J�e�S���̌n
       ,argument15    => NULL                    -- ����J�e�S��
       ,argument16    => NULL                    -- �i��:��
       ,argument17    => NULL                    -- �i��:��
       ,argument18    => NULL                    -- ���Y����:��
       ,argument19    => NULL                    -- ���Y����:��
       ,argument20    => NULL                    -- �Ԑڔ�:��
       ,argument21    => NULL                    -- �Ԑڔ�:��
       ,argument22    => 1                       -- �C�����|�[�g�̎��s(Yes)
       ,argument23    => 2                       -- �ڍׂ̕ۑ�(No)
      );
--
      --�R���J�����g�N���`�F�b�N
      IF ( ln_request_id <= 0 ) THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�W�������̍X�V���s�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        ROLLBACK;
        RAISE global_api_expt;
      END IF;
--
      --�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      -- �R���J�����g�I���ҋ@
      lb_ret := fnd_concurrent.wait_for_request(
        request_id    => ln_request_id      -- �v��ID
       ,interval      => 5                  -- �Ď��Ԋu
       ,max_wait      => 0                  -- �R���J�����g�Ď��ő厞��
       ,phase         => lv_phase           -- �t�F�[�Y
       ,status        => lv_status          -- �X�e�[�^�X
       ,dev_phase     => lv_dev_phase       -- �t�F�[�Y
       ,dev_status    => lv_dev_status      -- �X�e�[�^�X
       ,message       => lv_message         -- �������b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
         --�G���[���b�Z�[�W�o��
        lv_errmsg := '�R���J�����g�ҋ@�Ɏ��s���܂����B'
                   ||'�v��ID��'||ln_request_id;
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_cicd;
--
  /**********************************************************************************
   * Procedure Name   : proc_mic
   * Description      : DISC�i�ڃJ�e�S�������o�^�E�X�V(A-11)
   ***********************************************************************************/
  PROCEDURE proc_mic(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mic';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_inventory_item_id    mtl_system_items_b.inventory_item_id%TYPE;  -- �g�D�i��ID�i�[�p
    lt_category_set_id      gmi_item_categories.category_set_id%TYPE;   -- �J�e�S���E�Z�b�gID�i�[�p
    lt_category_id          gmi_item_categories.category_id%TYPE;       -- �J�e�S��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xmic_cur IS
      SELECT
        xmic.*
      FROM
        xxccp_mtl_item_categories xmic
      ORDER BY
        xmic.item_no
       ,xmic.category_set_id
       ,xmic.category_id
    ;
    TYPE l_xmic_ttype IS TABLE OF xxccp_mtl_item_categories%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xmic_rec l_xmic_ttype;
--
    -- *** ���[�J���E���R�[�h ***
    l_item_category_rec     xxcmm_004common_pkg.discitem_category_rtype;
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xmic_cur;
    FETCH l_xmic_cur BULK COLLECT INTO l_xmic_rec;
    CLOSE l_xmic_cur;
--
    << xmic_loop >>
    FOR i IN 1..l_xmic_rec.COUNT LOOP
      -- ===============================
      -- �g�D�i��ID�擾
      -- ===============================
      BEGIN
        -- DISC�i�ڃ}�X�^����g�D�i��ID�擾
        SELECT msib.inventory_item_id AS inventory_item_id
        INTO   lt_inventory_item_id
        FROM   mtl_system_items_b msib
        WHERE  msib.organization_id = gt_mst_org_id_t4
          AND  msib.segment1        = l_xmic_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W�o��
          lv_errmsg := '�g�D�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xmic_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      -- ===============================
      -- �J�e�S���E�Z�b�gID�A�J�e�S��ID�擾
      -- ===============================
      BEGIN
        SELECT mcs.category_set_id AS category_set_id
              ,mc.category_id      AS category_id
        INTO   lt_category_set_id
              ,lt_category_id
        FROM   mtl_category_sets mcs
              ,mtl_categories    mc
        WHERE  mc.structure_id       = mcs.structure_id
          AND  mcs.category_set_name = l_xmic_rec(i).category_set_name
          AND  mc.segment1           = l_xmic_rec(i).segment1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := '�J�e�S���E�Z�b�gID�A�J�e�S��ID�̎擾�Ɏ��s���܂����B'
                     ||'�J�e�S���E�Z�b�g��'||l_xmic_rec(i).category_set_name||'�A'
                     ||'�J�e�S����'        ||l_xmic_rec(i).segment1;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ���R�[�h�Z�b�g
      l_item_category_rec := NULL;
      l_item_category_rec.inventory_item_id := lt_inventory_item_id;
      l_item_category_rec.category_set_id   := lt_category_set_id;
      l_item_category_rec.category_id       := lt_category_id;
--
      -- ===============================
      -- �o�^�A�X�V�̏ꍇ
      -- ===============================
      IF ( l_xmic_rec(i).record_type IN ('I','U') ) THEN
        -- DISC�i�ڃJ�e�S�������o�^�E�X�V����
        xxcmm_004common_pkg.proc_discitem_categ_ref(
          i_item_category_rec => l_item_category_rec
         ,ov_errbuf           => lv_errbuf
         ,ov_retcode          => lv_retcode
         ,ov_errmsg           => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errbuf := lv_errmsg;
          lv_errmsg := 'DISC�i�ڃJ�e�S�������o�^�E�X�V�Ɏ��s���܂����B'
                     ||'�J�e�S���E�Z�b�g��'||l_xmic_rec(i).category_set_name||'�A'
                     ||'�J�e�S����'        ||l_xmic_rec(i).segment1         ||'�A'
                     ||'�i�ڃR�[�h��'      ||l_xmic_rec(i).item_no;
          RAISE global_api_expt;
        END IF;
        --
        IF ( l_xmic_rec(i).record_type = 'I' ) THEN
          -- �o�^�����J�E���g
          gn_mic_i_cnt := gn_mic_i_cnt + 1;
        ELSE
          -- �X�V�����J�E���g
          gn_mic_u_cnt := gn_mic_u_cnt + 1;
        END IF;
      END IF;
--
    END LOOP xmic_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_mic;
--
  /**********************************************************************************
   * Procedure Name   : proc_mucc
   * Description      : �P�ʊ��Z�}�X�^�o�^�E�X�V(A-12)
   ***********************************************************************************/
  PROCEDURE proc_mucc(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mucc';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;  -- �g�D�i��ID�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_xmucc_cur IS
      SELECT
        xmucc.*
      FROM
        xxccp_mtl_uom_class_convs xmucc
      ORDER BY
        xmucc.item_no
      , xmucc.to_uom_code
      , xmucc.to_uom_class
    ;
    TYPE l_xmucc_ttype IS TABLE OF xxccp_mtl_uom_class_convs%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xmucc_rec l_xmucc_ttype;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�J�[�\���I�[�v��
    OPEN l_xmucc_cur;
    FETCH l_xmucc_cur BULK COLLECT INTO l_xmucc_rec;
    CLOSE l_xmucc_cur;
--
    << xmucc_loop >>
    FOR i IN 1..l_xmucc_rec.COUNT LOOP
      -- ===============================
      -- �g�D�i��ID�擾
      -- ===============================
      BEGIN
        -- DISC�i�ڃ}�X�^����g�D�i��ID�擾
        SELECT msib.inventory_item_id AS inventory_item_id
        INTO   lt_inventory_item_id
        FROM   mtl_system_items_b msib
        WHERE  msib.organization_id = gt_mst_org_id_t4
          AND  msib.segment1        = l_xmucc_rec(i).item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := '�g�D�i��ID�̎擾�Ɏ��s���܂����B'
                     ||'�i�ڃR�[�h��'||l_xmucc_rec(i).item_no;
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- ===============================
      -- �o�^�̏ꍇ
      -- ===============================
      IF ( l_xmucc_rec(i).record_type = 'I' ) THEN
        BEGIN
          INSERT INTO mtl_uom_class_conversions(
            inventory_item_id
           ,from_unit_of_measure
           ,from_uom_code
           ,from_uom_class
           ,to_unit_of_measure
           ,to_uom_code
           ,to_uom_class
           ,conversion_rate
           ,disable_date
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login
           ,request_id
           ,program_application_id
           ,program_id
           ,program_update_date
          ) VALUES (
            lt_inventory_item_id
           ,l_xmucc_rec(i).from_unit_of_measure
           ,l_xmucc_rec(i).from_uom_code
           ,l_xmucc_rec(i).from_uom_class
           ,l_xmucc_rec(i).to_unit_of_measure
           ,l_xmucc_rec(i).to_uom_code
           ,l_xmucc_rec(i).to_uom_class
           ,l_xmucc_rec(i).conversion_rate
           ,l_xmucc_rec(i).disable_date
           ,l_xmucc_rec(i).created_by
           ,l_xmucc_rec(i).creation_date
           ,l_xmucc_rec(i).last_updated_by
           ,l_xmucc_rec(i).last_update_date
           ,l_xmucc_rec(i).last_update_login
           ,l_xmucc_rec(i).request_id
           ,l_xmucc_rec(i).program_application_id
           ,l_xmucc_rec(i).program_id
           ,l_xmucc_rec(i).program_update_date
          );
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := '�P�ʊ��Z�}�X�^�o�^�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xmucc_rec(i).item_no;
            RAISE global_api_others_expt;
        END;
        -- �o�^�����J�E���g
        gn_mucc_i_cnt := gn_mucc_i_cnt + 1;
      --
      -- ===============================
      -- �X�V�̏ꍇ
      -- ===============================
      ELSE
        BEGIN
          UPDATE mtl_uom_class_conversions mucc
          SET
            mucc.conversion_rate        = l_xmucc_rec(i).conversion_rate
           ,mucc.disable_date           = l_xmucc_rec(i).disable_date
           ,mucc.last_updated_by        = l_xmucc_rec(i).last_updated_by
           ,mucc.last_update_date       = l_xmucc_rec(i).last_update_date
           ,mucc.last_update_login      = l_xmucc_rec(i).last_update_login
           ,mucc.request_id             = l_xmucc_rec(i).request_id
           ,mucc.program_application_id = l_xmucc_rec(i).program_application_id
           ,mucc.program_id             = l_xmucc_rec(i).program_id
           ,mucc.program_update_date    = l_xmucc_rec(i).program_update_date
          WHERE mucc.inventory_item_id  = lt_inventory_item_id
            AND mucc.to_uom_code        = l_xmucc_rec(i).to_uom_code
            AND mucc.to_uom_class       = l_xmucc_rec(i).to_uom_class
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --�G���[���b�Z�[�W�o��
            lv_errmsg := '�P�ʊ��Z�}�X�^�X�V�Ɏ��s���܂����B'
                       ||'�i�ڃR�[�h��'||l_xmucc_rec(i).item_no;
            RAISE global_api_others_expt;
        END;
        -- �X�V�����J�E���g
        gn_mucc_u_cnt := gn_mucc_u_cnt + 1;
      END IF;
    END LOOP xmucc_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_mucc;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';              -- �v���O������
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �Ɩ����t�擾�G���[��
    IF ( gd_process_date IS NULL ) THEN
      --�G���[���b�Z�[�W�o��
      lv_errmsg := '�Ɩ����t�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾
    -- ===============================
    --��v����ID�擾
    gt_bks_id := TO_NUMBER(FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'));
    --
    -- ��v����ID�擾�G���[��
    IF ( gt_bks_id IS NULL ) THEN
      --�G���[���b�Z�[�W�o��
      lv_errmsg := '�v���t�@�C���uGL_SET_OF_BKS_ID�v�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�g�D�R�[�h�擾
    gt_org_code := FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE');
    --
    -- �v���t�@�C���l�擾�G���[��
    IF ( gt_org_code IS NULL ) THEN
      --�G���[���b�Z�[�W�o��
      lv_errmsg := '�v���t�@�C���uXXCOI1_ORGANIZATION_CODE�v�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ����v�N�x�擾
    -- ===============================
    BEGIN
      SELECT TO_CHAR(gp.period_year) AS calendar_code
      INTO   gt_calendar_code
      FROM   gl_sets_of_books gsob
            ,gl_periods       gp
      WHERE  gsob.set_of_books_id      = gt_bks_id
        AND  gp.period_set_name        = gsob.period_set_name
        AND  gp.adjustment_period_flag = 'N'  -- ������v���ԊO
        AND  gd_process_date BETWEEN gp.start_date
                                 AND gp.end_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '����v�N�x�̎擾�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �}�X�^�A�c�Ƒg�DID(�{�Ԋ�)�擾
    -- ===============================
    BEGIN
      SELECT mp.organization_id         AS org_id
            ,mp.master_organization_id  AS mst_org_id
      INTO   gt_org_id_hon
            ,gt_mst_org_id_hon
      FROM   mtl_parameters@t4_hon mp
      WHERE  mp.organization_code = gt_org_code  -- Z99
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�}�X�^�A�c�Ƒg�DID(�{�Ԋ�)�̎擾�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �}�X�^�A�c�Ƒg�DID(�����)�擾
    -- ===============================
    BEGIN
      SELECT mp.organization_id         AS org_id
            ,mp.master_organization_id  AS mst_org_id
      INTO   gt_org_id_t4
            ,gt_mst_org_id_t4
      FROM   mtl_parameters mp
      WHERE  mp.organization_code = gt_org_code  -- Z99
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�G���[���b�Z�[�W�o��
        lv_errmsg := '�}�X�^�A�c�Ƒg�DID(�����)�̎擾�Ɏ��s���܂����B';
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- ���ԃe�[�u��TRUNCATE
    -- ===============================
    -- OPM�i�ڃ}�X�^���ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_ic_item_mst_b';
    -- OPM�i�ڃA�h�I�����ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_xcmn_item_mst_b';
    -- OPM�i�ڃJ�e�S���������ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_gmi_item_categories';
    -- OPM�i�ڌ������ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_cm_cmpt_dtl';
    -- DISC�i�ڃ}�X�^���ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_mtl_system_items_b';
    -- DISC�i�ڃA�h�I�����ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_xcmm_system_items_b';
    -- DISC�i�ڃJ�e�S���������ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_mtl_item_categories';
    -- DISC�i�ڕύX�����A�h�I�����ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_xcmm_system_items_b_hst';
    -- DISC�i�ڌ������ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_cst_item_cost_details';
    -- �P�ʊ��Z�}�X�^���ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_mtl_uom_class_convs';
    -- �i�ڃJ�e�S�����ԃe�[�u��
    EXECUTE IMMEDIATE 'TRUNCATE TABLE xxccp.xxccp_mtl_categories_b';
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    -- �i�ڃJ�e�S������
    gn_mcb_i_cnt   := 0;
    gn_mcb_u_cnt   := 0;
    -- OPM�i�ڃ}�X�^����
    gn_iimb_i_cnt  := 0;
    gn_iimb_u_cnt  := 0;
    -- OPM�i�ڃA�h�I������
    gn_ximb_i_cnt  := 0;
    gn_ximb_u_cnt  := 0;
    -- OPM�i�ڌ�������
    gn_ccd_i_cnt   := 0;
    gn_ccd_u_cnt   := 0;
    -- OPM�i�ڃJ�e�S����������
    gn_gic_i_cnt   := 0;
    gn_gic_u_cnt   := 0;
    -- DISC�i�ڃ}�X�^����
    gn_msib_i_cnt  := 0;
    gn_msib_u_cnt  := 0;
    -- DISC�i�ڃA�h�I������
    gn_xsib_i_cnt  := 0;
    gn_xsib_u_cnt  := 0;
    -- DISC�i�ڕύX�����A�h�I������
    gn_xsibh_i_cnt := 0;
    gn_xsibh_u_cnt := 0;
    gn_xsibh_d_cnt := 0;
    -- DISC�i�ڃJ�e�S������
    gn_mic_i_cnt   := 0;
    gn_mic_u_cnt   := 0;
    -- DISC�i�ڌ�������
    gn_cicd_i_cnt  := 0;
    gn_cicd_u_cnt  := 0;
    -- �P�ʊ��Z�}�X�^����
    gn_mucc_i_cnt  := 0;
    gn_mucc_u_cnt  := 0;
    -- LOOKUP�\�L���`�F�b�N
    gv_chk_retcode := cv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- ��������(A-1)
    --==============================================================
    init(
      ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �������R�[�h�擾(A-2)
    --==============================================================
    get_diff_record(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_normal ) THEN
      -- �������R�[�h�擾�����̏ꍇ�A�R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �i�ڃJ�e�S���o�^�E�X�V(A-3)
    --==============================================================
    proc_mcb(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- OPM�i�ڃ}�X�^�o�^�E�X�V(A-4)
    --==============================================================
    proc_iimb(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- OPM�i�ڃA�h�I���o�^�E�X�V(A-5)
    --==============================================================
    proc_ximb(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- OPM�i�ڌ����o�^�E�X�V(A-6)
    --==============================================================
    proc_ccd(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- OPM�i�ڃJ�e�S�������o�^�E�X�V(A-7)
    --==============================================================
    proc_gic(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- DISC�i�ڃ}�X�^�o�^�E�X�V(A-8)
    --==============================================================
    proc_msib(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- DISC�i�ڃA�h�I���o�^�E�X�V(A-9)
    --==============================================================
    proc_xsib(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- DISC�i�ڕύX�����A�h�I���o�^�E�X�V(A-10)
    --==============================================================
    proc_xsibh(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- DISC�i�ڃJ�e�S�������o�^�E�X�V(A-11)
    --==============================================================
    proc_mic(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �P�ʊ��Z�}�X�^�o�^�E�X�V(A-12)
    --==============================================================
    proc_mucc(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- DISC�i�ڌ����o�^�E�X�V(A-13)
    --==============================================================
    proc_cicd(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- LOOKUP�\�`�F�b�NNG�̏ꍇ�͌x���I��
    IF ( gv_chk_retcode = cv_status_warn ) THEN
      ov_retcode := gv_chk_retcode;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h        --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- ����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '���̓p�����[�^�Ȃ�'
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --==============================================================
    -- �I������(A-14)
    --==============================================================
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      IF lv_errmsg IS NULL THEN
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '�\�����ʃG���[���������܂����B' --���[�U�[�G���[���b�Z�[�W
        );
      ELSE
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
--
    --���������o��
    gv_out_msg := '*** �i�ڃJ�e�S�� ***'             ||CHR(10)||
                  '�o�^���� �F '||gn_mcb_i_cnt       ||CHR(10)||
                  '�X�V���� �F '||gn_mcb_u_cnt       ||CHR(10)||
                  '*** OPM�i�ڃ}�X�^ ***'            ||CHR(10)||
                  '�o�^���� �F '||gn_iimb_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_iimb_u_cnt      ||CHR(10)||
                  '*** OPM�i�ڃA�h�I�� ***'          ||CHR(10)||
                  '�o�^���� �F '||gn_ximb_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_ximb_u_cnt      ||CHR(10)||
                  '*** OPM�i�ڌ��� ***'              ||CHR(10)||
                  '�o�^���� �F '||gn_ccd_i_cnt       ||CHR(10)||
                  '�X�V���� �F '||gn_ccd_u_cnt       ||CHR(10)||
                  '*** OPM�i�ڃJ�e�S������ ***'      ||CHR(10)||
                  '�o�^���� �F '||gn_gic_i_cnt       ||CHR(10)||
                  '�X�V���� �F '||gn_gic_u_cnt       ||CHR(10)||
                  '*** DISC�i�ڃ}�X�^ ***'           ||CHR(10)||
                  '�o�^���� �F '||gn_msib_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_msib_u_cnt      ||CHR(10)||
                  '*** DISC�i�ڃA�h�I�� ***'         ||CHR(10)||
                  '�o�^���� �F '||gn_xsib_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_xsib_u_cnt      ||CHR(10)||
                  '*** DISC�i�ڕύX�����A�h�I�� ***' ||CHR(10)||
                  '�o�^���� �F '||gn_xsibh_i_cnt     ||CHR(10)||
                  '�X�V���� �F '||gn_xsibh_u_cnt     ||CHR(10)||
                  '�폜���� �F '||gn_xsibh_d_cnt     ||CHR(10)||
                  '*** DISC�i�ڃJ�e�S������ ***'     ||CHR(10)||
                  '�o�^���� �F '||gn_mic_i_cnt       ||CHR(10)||
                  '�X�V���� �F '||gn_mic_u_cnt       ||CHR(10)||
                  '*** DISC�i�ڌ��� ***'             ||CHR(10)||
                  '�o�^���� �F '||gn_cicd_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_cicd_u_cnt      ||CHR(10)||
                  '*** �P�ʊ��Z�}�X�^ ***'           ||CHR(10)||
                  '�o�^���� �F '||gn_mucc_i_cnt      ||CHR(10)||
                  '�X�V���� �F '||gn_mucc_u_cnt
    ;
    --
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      gv_out_msg := '����������I�����܂����B';
    ELSIF( lv_retcode = cv_status_warn ) THEN
      gv_out_msg := '�������x���I�����܂����B';
    ELSIF( lv_retcode = cv_status_error ) THEN
      gv_out_msg := '�������G���[�I�����܂����B'
                  ||'�ꕔ�f�[�^�́A�S�������O�̏�Ԃɖ߂��܂����B';
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_appl_xxccp
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP011A01C;
/
