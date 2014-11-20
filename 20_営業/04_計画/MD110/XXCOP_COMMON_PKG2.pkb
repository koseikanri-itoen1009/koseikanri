create or replace PACKAGE BODY XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W2(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.�i�ڏ��擾����
 * get_org_info              11.�g�D���擾����
 * get_num_of_shipped        12.�o�׎��ю擾����
 * get_num_of_forcast        13.�o�ח\���擾����
 * get_stock_plan            14.���ɗ\��擾����
 * get_onhand_qty            15.�莝�݌Ɏ擾����
 * get_deliv_lead_time       16.�z�����[�h�^�C���擾����
 * get_unit_delivery         17.�z���P�ʎ擾����
 * get_working_days          18.�ғ������擾����
 * chk_item_exists           19.�݌ɕi�ڃ`�F�b�N
 * get_scheduled_trans       20.���o�ɗ\��擾����
 * upd_assignment            21.�ړ��˗��E�����Z�b�gAPI�N��
 * get_loct_info             22.�q�ɏ��擾����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   �V�K�쐬
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'xxcop_common_pkg2';       -- �p�b�P�[�W��
--
--
  -- ===============================
  -- ���[�U�[��`�萔
  -- ===============================
  cd_sys_date               CONSTANT DATE        := SYSDATE;
  cn_zero                   CONSTANT NUMBER      := 0;
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  date_null_expt            EXCEPTION;
  date_from_to_expt         EXCEPTION;
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : �i�ڏ��擾����
   ***********************************************************************************/
  PROCEDURE get_item_info(
    in_inventory_item_id IN  NUMBER,
    on_item_id           OUT  NUMBER,
    ov_item_no           OUT  VARCHAR2,
    ov_item_name         OUT  VARCHAR2,
    ov_prod_class_code   OUT  VARCHAR2,
    on_num_of_case       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_info'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_inactive_ind           CONSTANT NUMBER          := 1;          -- �����`�F�b�N����
    cv_inv_status_code_inactive CONSTANT VARCHAR2(100) := 'Inactive'; -- ����
--
    -- *** ���[�J���ϐ� ***
    ln_item_id           ic_item_mst_b.item_id%TYPE;
    lv_item_no           ic_item_mst_b.item_no%TYPE;
    lv_item_name         VARCHAR2(50);
    lv_prod_class_code   VARCHAR2(50);
    lv_num_of_case       ic_item_mst_b.attribute11%type;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�i�ڏ��擾
    --==============================================================
    SELECT xicv.item_id
          ,xicv.item_no
          ,xicv.item_short_name
          ,xicv.prod_class_code
          ,xicv.num_of_cases
    INTO   ln_item_id
          ,lv_item_no
          ,lv_item_name
          ,lv_prod_class_code
          ,lv_num_of_case
    FROM   xxcop_item_categories1_v      xicv
    WHERE  xicv.inventory_item_id           = in_inventory_item_id
    AND    xicv.start_date_active          <= cd_sys_date
    AND    xicv.end_date_active            >= cd_sys_date
    AND    xicv.inactive_ind               <> cn_inactive_ind
    AND    xicv.inventory_item_status_code <> cv_inv_status_code_inactive
    ;
    on_item_id           :=  ln_item_id;
    ov_item_no           :=  lv_item_no;
    ov_item_name         :=  lv_item_name;
    ov_prod_class_code   :=  lv_prod_class_code;
--20090408_Ver1.1_T1_0282_SCS.Kikuchi_MOD_START
--    on_num_of_case       :=  TO_NUMBER(lv_num_of_case);
    on_num_of_case       :=  NVL(TO_NUMBER(lv_num_of_case),1);
--20090408_Ver1.1_T1_0282_SCS.Kikuchi_MOD_END
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_item_id       := NULL;
      ov_item_no       := NULL;
      ov_item_name     := NULL;
      ov_prod_class_code := NULL;
      on_num_of_case     := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_item_id       := NULL;
      ov_item_no       := NULL;
      ov_item_name     := NULL;
      ov_prod_class_code := NULL;
      on_num_of_case     := NULL;
  END get_item_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_org_info
   * Description      : �g�D���擾����
   ***********************************************************************************/
  PROCEDURE get_org_info(
    in_organization_id   IN  NUMBER,
    ov_organization_code OUT  VARCHAR2,
    ov_whse_name         OUT  VARCHAR2,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_org_info'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- �L��
--
    -- *** ���[�J���ϐ� ***
    lv_organization_code mtl_parameters.organization_code%TYPE;
    lv_whse_name         ic_whse_mst.whse_name%TYPE;
    lv_loct_cnt          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�g�D���擾
    --==============================================================
    SELECT mp.organization_code                --  �g�D�R�[�h
          ,iwm.whse_name                       --  �q�ɖ�
    INTO   lv_organization_code
          ,lv_whse_name
    FROM   mtl_parameters              mp,      --  �g�D�p�����[�^
           ic_whse_mst                 iwm,     --  OPM�q�Ƀ}�X�^
           hr_all_organization_units   haou     --  �݌ɑg�D�}�X�^
    WHERE  mp.organization_id       = haou.organization_id
    AND    haou.date_from          <= trunc(cd_sys_date)
    AND   (haou.date_to           >= trunc(cd_sys_date)
     OR    haou.date_to           IS NULL)
    AND    iwm.mtl_organization_id  = haou.organization_id
    AND    iwm.delete_mark          = cn_del_mark_n
    AND    haou.organization_id     = in_organization_id
    ;
    --
    --��2009/02/16�@�ǉ�
    --==============================================================
    --�q�ɑ��݃`�F�b�N
    --==============================================================
    SELECT COUNT(ilm.location)                  --  �q�ɃR�[�h�i�����j
    INTO   lv_loct_cnt
    FROM   ic_loct_mst                 ilm      --  OPM�ۊǃ}�X�^
    WHERE  ilm.whse_code = lv_organization_code
    AND    ilm.delete_mark = cn_del_mark_n
    ;
    IF lv_loct_cnt = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    --��2009/02/16�@�ǉ�
    --
    ov_organization_code :=  lv_organization_code;
    ov_whse_name         :=  lv_whse_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      ov_organization_code := NULL;
      ov_whse_name         := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      ov_organization_code := NULL;
      ov_whse_name         := NULL;
  END get_org_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : �o�׎��ю擾����
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    iv_organization_code IN  VARCHAR2,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_shipped'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;                        -- �L��
--
    -- *** ���[�J���ϐ� ***
    ln_qty               NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�o�׎��ю擾
    --==============================================================
    SELECT NVL(SUM(xsr.quantity),0)
    INTO   ln_qty
    FROM   xxcop_shipment_results  xsr
    WHERE  xsr.shipment_date      >= TRUNC(id_plan_date_from)
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_START
--    AND    xsr.shipment_date      <= TRUNC(id_plan_date_to)
    AND    xsr.shipment_date      < TRUNC(id_plan_date_to)
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_END
    AND    xsr.item_no             = iv_item_no
    AND    xsr.latest_deliver_from IN (
      SELECT ilm.location
      FROM   ic_loct_mst  ilm
      WHERE  ilm.whse_code   = iv_organization_code
      AND    ilm.delete_mark = cn_del_mark_n
      )
    ;
    on_quantity :=  ln_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_shipped;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_forcast
   * Description      : �o�ח\���擾����
   ***********************************************************************************/
  PROCEDURE get_num_of_forcast(
    in_organization_id   IN  NUMBER,
    in_inventory_item_id IN  NUMBER,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_forcast'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_del_mark_n             CONSTANT NUMBER        := 0;   -- �L��
    cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1'; -- ��v�敪�ށi�o�ח\���j
    cn_schedule_level         CONSTANT NUMBER        := 2;   -- ��v�惌�x���i���x���Q�j
--
    -- *** ���[�J���ϐ� ***
    ln_qty               NUMBER   := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�o�ח\���擾
    --==============================================================
    SELECT NVL(SUM(msdd.schedule_quantity),0)
    INTO   ln_qty
    FROM   mrp_schedule_dates       msdd
          ,mrp_schedule_designators msdh
    WHERE  msdh.schedule_designator = msdd.schedule_designator
    AND    msdh.organization_id     = in_organization_id
    AND    msdh.organization_id     = msdd.organization_id
    AND    msdh.attribute1          = cv_ship_plan_type
    AND    msdd.schedule_date      >= id_plan_date_from
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_START
--    AND    msdd.schedule_date      <= id_plan_date_to
    AND    msdd.schedule_date      <  id_plan_date_to
--20090408_Ver1.1_T1_0284_SCS.Kikuchi_MOD_END
    AND    msdd.inventory_item_id   = in_inventory_item_id
    AND    msdd.schedule_level      = cn_schedule_level
    ;
    on_quantity :=  ln_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_forcast;
  --
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : ���ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_plan'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_xstv_status            CONSTANT VARCHAR2(1)       := '1';  -- �\��
--
    -- *** ���[�J���ϐ� ***
    ln_stock_qty              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --���ɗ\��擾����
    --==============================================================
    SELECT NVL(SUM(xstv.stock_quantity),0)     --���ɐ�
    INTO   ln_stock_qty
    FROM   xxcop_stc_trans_v	xstv
    WHERE  xstv.arrival_date        >= id_plan_date_from
--20090408_Ver1.1_T1_0279_SCS.Kikuchi_MOD_START
--    AND    xstv.arrival_date        <= id_plan_date_to
    AND    xstv.arrival_date        <  id_plan_date_to
--20090408_Ver1.1_T1_0279_SCS.Kikuchi_MOD_END
    AND    xstv.organization_id     =  in_organization_id
    AND    xstv.item_no             =  iv_item_no
    AND    xstv.status              =  cv_xstv_status    --1�F�\��
    ;
    on_quantity :=  ln_stock_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_stock_plan;
  --
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : �莝�݌Ɏ擾����
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    iv_organization_code IN  VARCHAR2,
    in_item_id           IN  NUMBER,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_onhand_qty'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_onhand_qty              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�莝�݌Ɏ擾
    --==============================================================
    SELECT NVL(SUM(ili.loct_onhand),0)
    INTO  ln_onhand_qty
    FROM  ic_loct_inv ili
         ,ic_lots_mst ilm
    WHERE ili.item_id     =  in_item_id
    AND   ili.whse_code   =  iv_organization_code
    AND   ili.item_id     =  ilm.item_id
    AND   ili.lot_id      =  ilm.lot_id;
    on_quantity :=  ln_onhand_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_onhand_qty;
  --
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : �z�����[�h�^�C���擾����
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    iv_from_org_code     IN  VARCHAR2,
    iv_to_org_code       IN  VARCHAR2,
    id_product_date      IN  DATE,
    on_delivery_lt       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lead_time'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_del_mark_n  CONSTANT NUMBER        := 0;                        -- �L��
    cv_code_class  CONSTANT VARCHAR2(1) := '4';  -- �q��
    ln_dlt_cnt     NUMBER := 0;
--
    -- *** ���[�J���ϐ� ***
    ln_delivery_lead_time      NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�z�����[�h�^�C���擾
    --==============================================================
    SELECT MAX(delivery_lead_time)
          ,COUNT(delivery_lead_time)
    INTO   ln_delivery_lead_time
          ,ln_dlt_cnt
    FROM   xxcmn_delivery_lt
    WHERE  code_class1 = cv_code_class      --�q��
    AND    code_class2 = cv_code_class      --�q��
    AND(
        (entering_despatching_code1 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_from_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
    AND  entering_despatching_code2 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_to_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
        )
    OR  (entering_despatching_code1 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_to_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
    AND  entering_despatching_code2 In (SELECT ic_loct_mst.location
                                        FROM   ic_loct_mst
                                        WHERE  ic_loct_mst.whse_code = iv_from_org_code
                                        AND    ic_loct_mst.delete_mark = cn_del_mark_n
                                        )
        )
      )
    AND start_date_active <= id_product_date
    AND end_date_active   >= id_product_date
    ;
    IF ln_dlt_cnt = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    on_delivery_lt := ln_delivery_lead_time;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
  END get_deliv_lead_time;
  --
  /**********************************************************************************
   * Procedure Name   : get_unit_delivery
   * Description      : �z���P�ʎ擾����
   ***********************************************************************************/
  PROCEDURE get_unit_delivery(
    in_item_id              IN  NUMBER,              --   OPM�i��ID
    id_ship_date            IN  DATE,                --   �o�ד�
    on_palette_max_cs_qty   OUT  NUMBER,       --   �z��
    on_palette_max_step_qty OUT  NUMBER,       --   �i��
    ov_errbuf               OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_delivery'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_active                 CONSTANT VARCHAR2(1)     := 'Y';        -- �L���t���O
--
    -- *** ���[�J���ϐ� ***
    ln_palette_max_cs_qty   xxcmn_item_mst_b.palette_max_cs_qty%TYPE;
    ln_palette_max_step_qty xxcmn_item_mst_b.palette_max_step_qty%TYPE;

--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�z���P�ʎ擾����
    --==============================================================
    SELECT palette_max_cs_qty
          ,palette_max_step_qty
    INTO   ln_palette_max_cs_qty
          ,ln_palette_max_step_qty
    FROM   xxcmn_item_mst_b
    WHERE  item_id = in_item_id
    AND    start_date_active <= id_ship_date
    AND    NVL(end_date_active,id_ship_date) >=  id_ship_date
    AND    active_flag = cv_active
    ;
--20090408_Ver1.1_T1_0272_SCS.Kikuchi_MOD_START
--    on_palette_max_cs_qty    := ln_palette_max_cs_qty;
--    on_palette_max_step_qty  := ln_palette_max_step_qty;
    on_palette_max_cs_qty    := NVL(ln_palette_max_cs_qty,1);
    on_palette_max_step_qty  := NVL(ln_palette_max_step_qty,1);
--20090408_Ver1.1_T1_0272_SCS.Kikuchi_MOD_END
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_palette_max_cs_qty   := NULL;
      on_palette_max_step_qty := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_palette_max_cs_qty   := NULL;
      on_palette_max_step_qty := NULL;
  END get_unit_delivery;
--
  /**********************************************************************************
   * Function Name   : get_working_days
   * Description      : �ғ������擾����
   ***********************************************************************************/
  PROCEDURE get_working_days(
    in_organization_id   IN NUMBER,
    id_from_date     IN     DATE,           --   ��_���t
    id_to_date       IN     DATE,           --   �I�_���t
    on_working_days  OUT    NUMBER,
    ov_errbuf        OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_working_days'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    ld_work_date  DATE := NULL;
    ld_from_date  DATE := NULL;
    ln_cnt_days   NUMBER := 0;
    lv_calendar_code mtl_parameters.calendar_code%TYPE := NULL;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ===============================
    -- �p�����[�^�`�F�b�N
    -- ===============================
    IF id_from_date IS NULL OR id_to_date IS NULL THEN
      RAISE date_null_expt;
    END IF;
    IF id_from_date > id_to_date THEN
      RAISE date_from_to_expt;
    END IF;
    -- ===============================
    -- �ғ������擾
    -- ===============================
    -- �ϐ�������
    ld_from_date := id_from_date;
    --
    SELECT calendar_code
    INTO lv_calendar_code
    FROM mtl_parameters
    WHERE organization_id = in_organization_id;
    <<loop_bomdays>>
    LOOP
      IF id_from_date = id_to_date THEN
        on_working_days := 0;
        EXIT;
      END IF;
      --�ғ����̏ꍇ���t���߂�A��ғ����̏ꍇNULL���߂�
      ld_work_date := xxccp_common_pkg2.get_working_day(
                       id_date            =>  ld_from_date
                      ,in_working_day     =>  0
                      ,iv_calendar_code   =>  lv_calendar_code
                      );
      --
      IF ld_work_date IS NOT NULL THEN
        --�ғ����J�E���g
        ln_cnt_days  := ln_cnt_days  + 1;
      END IF;
      --
      ld_from_date  := ld_from_date + 1;
      --
      IF ld_from_date >= id_to_date THEN
        on_working_days := ln_cnt_days;
        EXIT;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_working_days  := NULL;
--
  END get_working_days;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_exists
   * Description      : �݌ɕi�ڃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_item_exists(
    in_inventory_item_id IN  NUMBER,
    in_organization_id   IN  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_exists'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_inventory_item_id mtl_system_items_b.inventory_item_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�݌ɕi�ڃ`�F�b�N
    --==============================================================
    SELECT msib.inventory_item_id
    INTO   ln_inventory_item_id
    FROM   mtl_system_items_b msib
    WHERE  msib.inventory_item_id = in_inventory_item_id
    AND    msib.organization_id   = in_organization_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
  END chk_item_exists;
  --
  /**********************************************************************************
   * Procedure Name   : get_scheduled_trans
   * Description      : ���o�ɗ\��擾����
   ***********************************************************************************/
  PROCEDURE get_scheduled_trans(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_date_from         IN  DATE,
    id_date_to           IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT  VARCHAR2)
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_scheduled_trans'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_xstv_status            CONSTANT VARCHAR2(1)       := '1';  -- �\��
--
    -- *** ���[�J���ϐ� ***
    ln_stock_qty              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --���ɗ\��擾����
    --==============================================================
    SELECT NVL(SUM(xstv.stock_quantity),0) - NVL(SUM(xstv.leaving_quantity), 0)
    INTO   ln_stock_qty
    FROM   xxcop_stc_trans_v xstv
    WHERE  xstv.organization_id   =  in_organization_id
    AND    xstv.item_no           =  iv_item_no
    AND    xstv.status            =  cv_xstv_status
    AND    xstv.arrival_date BETWEEN id_date_from AND id_date_to
    ;
    on_quantity :=  ln_stock_qty;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_scheduled_trans;
  --
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : �ړ��˗��E�����Z�b�gAPI�N��
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_ship_to_locat_code   IN  VARCHAR2,     -- ���ɐ�
    iv_item_code            IN  VARCHAR2,     -- �i��
    in_quantity             IN  NUMBER,       -- �ړ���(0�ȏ�:���Z�A0����:���Z)
    iv_design_prod_date     IN  VARCHAR2,     -- �w�萻����
    iv_sche_arriv_date      IN  VARCHAR2,     -- ����
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'upd_assignment';   -- �v���V�[�W����
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�U�[��`��O ***
    api_expt                  EXCEPTION;
--
    -- *** ���[�J���萔 ***
    -- API�萔
    cv_operation_update       CONSTANT VARCHAR2(6) := 'UPDATE';   -- �X�V
    cv_api_version            CONSTANT VARCHAR2(4) := '1.0';      -- �o�[�W����
    cv_msg_encoded            CONSTANT VARCHAR2(1) := 'F';        -- �G���[���b�Z�[�W�G���R�[�h
    -- ���̑�
    cv_date_format            CONSTANT VARCHAR2(8) := 'YYYYMMDD';   -- �V�X�e�����t
    cv_slash                  CONSTANT VARCHAR2(1) := '/';          -- ���t�̋�؂�L��
    cv_attribute_category     CONSTANT VARCHAR2(1) := '2';          -- �����Z�b�g�敪(2:���ʉ���)
    cv_assignment_type        CONSTANT VARCHAR2(1) := '6';          -- ������^�C�v(6:�i�ځE�g�D)
    cv_sourcing_rule_type     CONSTANT VARCHAR2(1) := '1';          -- �����\���\/�\�[�X���[���^�C�v(1:�\�[�X���[��)
--
    -- *** ���[�J���ϐ� ***
    lv_message_code           VARCHAR2(100);
    lv_param                  VARCHAR2(256);    -- �p�����[�^
    lv_return_status          VARCHAR2(1);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(3000);
    ln_msg_index_out          NUMBER;
    ln_quantity               NUMBER;           -- �ړ���
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR l_assignments_set_cur IS
      -- �����Z�b�g���ׂ̍X�V�Ώۃf�[�^�擾
      SELECT mas.assignment_set_id      mas_assignment_set_id     -- �����Z�b�g�w�b�_.�����Z�b�g�w�b�_ID
            ,mas.assignment_set_name    assignment_set_name       -- �����Z�b�g�w�b�_.�����Z�b�g��
            ,mas.creation_date          mas_creation_date         -- �����Z�b�g�w�b�_.�쐬��
            ,mas.created_by             mas_created_by            -- �����Z�b�g�w�b�_.�쐬��
            ,mas.description            description               -- �����Z�b�g�w�b�_.�����Z�b�g�E�v
            ,mas.attribute_category     mas_attribute_category    -- �����Z�b�g�w�b�_.Attribute_Category
            ,mas.attribute1             mas_attribute1            -- �����Z�b�g�w�b�_.�����Z�b�g�敪(DFF1)
            ,mas.attribute2             mas_attribute2            -- �����Z�b�g�w�b�_.DFF2
            ,mas.attribute3             mas_attribute3            -- �����Z�b�g�w�b�_.DFF3
            ,mas.attribute4             mas_attribute4            -- �����Z�b�g�w�b�_.DFF4
            ,mas.attribute5             mas_attribute5            -- �����Z�b�g�w�b�_.DFF5
            ,mas.attribute6             mas_attribute6            -- �����Z�b�g�w�b�_.DFF6
            ,mas.attribute7             mas_attribute7            -- �����Z�b�g�w�b�_.DFF7
            ,mas.attribute8             mas_attribute8            -- �����Z�b�g�w�b�_.DFF8
            ,mas.attribute9             mas_attribute9            -- �����Z�b�g�w�b�_.DFF9
            ,mas.attribute10            mas_attribute10           -- �����Z�b�g�w�b�_.DFF10
            ,mas.attribute11            mas_attribute11           -- �����Z�b�g�w�b�_.DFF11
            ,mas.attribute12            mas_attribute12           -- �����Z�b�g�w�b�_.DFF12
            ,mas.attribute13            mas_attribute13           -- �����Z�b�g�w�b�_.DFF13
            ,mas.attribute14            mas_attribute14           -- �����Z�b�g�w�b�_.DFF14
            ,mas.attribute15            mas_attribute15           -- �����Z�b�g�w�b�_.DFF15
            ,mss.assignment_id          assignment_id             -- �����Z�b�g����.�����Z�b�g����ID
            ,mss.assignment_type        assignment_type           -- �����Z�b�g����.������^�C�v
            ,mss.sourcing_rule_id       sourcing_rule_id          -- �����Z�b�g����.�\�[�X���[��ID
            ,mss.sourcing_rule_type     sourcing_rule_type        -- �����Z�b�g����.�����\���\/�\�[�X���[���^�C�v
            ,mss.assignment_set_id      mss_assignment_set_id     -- �����Z�b�g����.�����Z�b�g�w�b�_ID
            ,mss.creation_date          mss_creation_date         -- �����Z�b�g����.�쐬��
            ,mss.created_by             mss_created_by            -- �����Z�b�g����.�쐬��
            ,mss.organization_id        organization_id           -- �����Z�b�g����.�g�DID
            ,mss.customer_id            customer_id               -- �����Z�b�g����.Customer_Id
            ,mss.ship_to_site_id        ship_to_site_id           -- �����Z�b�g����.Ship_To_Site_Id
            ,mss.category_id            category_id               -- �����Z�b�g����.Category_Id
            ,mss.category_set_id        category_set_id           -- �����Z�b�g����.Category_Set_Id
            ,mss.inventory_item_id      inventory_item_id         -- �����Z�b�g����.�i��ID
            ,mss.secondary_inventory    secondary_inventory       -- �����Z�b�g����.Secondary_Inventory
            ,mss.attribute_category     mss_attribute_category    -- �����Z�b�g����.�����Z�b�g�敪
            ,mss.attribute1             mss_attribute1            -- �����Z�b�g����.�J�n�����N����(DFF1)
            ,mss.attribute2             mss_attribute2            -- �����Z�b�g����.�L���J�n��(DFF2)
            ,mss.attribute3             mss_attribute3            -- �����Z�b�g����.�L���I����(DFF3)
            ,mss.attribute4             mss_attribute4            -- �����Z�b�g����.�ݒ萔��(DFF4)
            ,mss.attribute5             mss_attribute5            -- �����Z�b�g����.�ړ���(DFF5)
            ,mss.attribute6             mss_attribute6            -- �����Z�b�g����.DFF6
            ,mss.attribute7             mss_attribute7            -- �����Z�b�g����.DFF7
            ,mss.attribute8             mss_attribute8            -- �����Z�b�g����.DFF8
            ,mss.attribute9             mss_attribute9            -- �����Z�b�g����.DFF9
            ,mss.attribute10            mss_attribute10           -- �����Z�b�g����.DFF10
            ,mss.attribute11            mss_attribute11           -- �����Z�b�g����.DFF11
            ,mss.attribute12            mss_attribute12           -- �����Z�b�g����.DFF12
            ,mss.attribute13            mss_attribute13           -- �����Z�b�g����.DFF13
            ,mss.attribute14            mss_attribute14           -- �����Z�b�g����.DFF14
            ,mss.attribute15            mss_attribute15           -- �����Z�b�g����.DFF15
      FROM   mrp_assignment_sets mas          -- �����Z�b�g�w�b�_
            ,mrp_sr_assignments mss           -- �����Z�b�g����
            ,mtl_item_locations mil           -- OPM�ۊǏꏊ�}�X�^
            ,xxcop_item_categories1_v xicv    -- �v��_�i�ڃJ�e�S���r���[1
      WHERE  mas.attribute1         = cv_attribute_category   -- �����Z�b�g�敪(2:���ʉ���)
      AND    mas.assignment_set_id  = mss.assignment_set_id
      AND    mss.assignment_type    = cv_assignment_type      -- ������^�C�v(6:�i�ځE�g�D)
      AND    mss.sourcing_rule_type = cv_sourcing_rule_type   -- �����\���\/�\�[�X���[���^�C�v(1:�\�[�X���[��)
      AND    mil.segment1           = iv_ship_to_locat_code   -- ���ɐ�
      AND    mss.organization_id    = mil.organization_id
      AND    xicv.item_no           = iv_item_code            -- �i��
      AND    mss.inventory_item_id  = xicv.inventory_item_id
      AND    NVL( REPLACE( mss.attribute1, cv_slash ), iv_design_prod_date ) <= iv_design_prod_date
      AND    NVL( REPLACE( mss.attribute2, cv_slash ), iv_sche_arriv_date  ) <= iv_sche_arriv_date
      AND    NVL( REPLACE( mss.attribute3, cv_slash ), iv_sche_arriv_date  ) >= iv_sche_arriv_date
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_in_mas_rec              MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;        -- �����Z�b�g�w�b�_�[
    l_mas_val_rec             MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
    l_out_mas_rec             MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;
    l_out_mas_val_rec         MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
--
    -- *** ���[�J���EPL/SQL�\ ***
    l_in_msa_tab              MRP_Src_Assignment_PUB.Assignment_Tbl_Type;            -- �����Z�b�g����
    l_msa_val_tab             MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
    l_out_msa_tab             MRP_Src_Assignment_PUB.Assignment_Tbl_Type;
    l_out_msa_val_tab         MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �����Z�b�g���ׂ̍X�V�Ώۃf�[�^���擾����
    -- ===============================================
    OPEN l_assignments_set_cur;
    FETCH l_assignments_set_cur INTO
      l_in_mas_rec.assignment_set_id          -- �����Z�b�g�w�b�_.�����Z�b�g�w�b�_ID
     ,l_in_mas_rec.assignment_set_name        -- �����Z�b�g�w�b�_.�����Z�b�g��
     ,l_in_mas_rec.creation_date              -- �����Z�b�g�w�b�_.�쐬��
     ,l_in_mas_rec.created_by                 -- �����Z�b�g�w�b�_.�쐬��
     ,l_in_mas_rec.description                -- �����Z�b�g�w�b�_.�����Z�b�g�E�v
     ,l_in_mas_rec.attribute_category         -- �����Z�b�g�w�b�_.Attribute_Category
     ,l_in_mas_rec.attribute1                 -- �����Z�b�g�w�b�_.�����Z�b�g�敪(DFF1)
     ,l_in_mas_rec.attribute2                 -- �����Z�b�g�w�b�_.DFF2
     ,l_in_mas_rec.attribute3                 -- �����Z�b�g�w�b�_.DFF3
     ,l_in_mas_rec.attribute4                 -- �����Z�b�g�w�b�_.DFF4
     ,l_in_mas_rec.attribute5                 -- �����Z�b�g�w�b�_.DFF5
     ,l_in_mas_rec.attribute6                 -- �����Z�b�g�w�b�_.DFF6
     ,l_in_mas_rec.attribute7                 -- �����Z�b�g�w�b�_.DFF7
     ,l_in_mas_rec.attribute8                 -- �����Z�b�g�w�b�_.DFF8
     ,l_in_mas_rec.attribute9                 -- �����Z�b�g�w�b�_.DFF9
     ,l_in_mas_rec.attribute10                -- �����Z�b�g�w�b�_.DFF10
     ,l_in_mas_rec.attribute11                -- �����Z�b�g�w�b�_.DFF11
     ,l_in_mas_rec.attribute12                -- �����Z�b�g�w�b�_.DFF12
     ,l_in_mas_rec.attribute13                -- �����Z�b�g�w�b�_.DFF13
     ,l_in_mas_rec.attribute14                -- �����Z�b�g�w�b�_.DFF14
     ,l_in_mas_rec.attribute15                -- �����Z�b�g�w�b�_.DFF15
     ,l_in_msa_tab(1).assignment_id           -- �����Z�b�g����.�����Z�b�g����ID
     ,l_in_msa_tab(1).assignment_type         -- �����Z�b�g����.������^�C�v
     ,l_in_msa_tab(1).sourcing_rule_id        -- �����Z�b�g����.�\�[�X���[��ID
     ,l_in_msa_tab(1).sourcing_rule_type      -- �����Z�b�g����.�����\���\/�\�[�X���[���^�C�v
     ,l_in_msa_tab(1).assignment_set_id       -- �����Z�b�g����.�����Z�b�g�w�b�_ID
     ,l_in_msa_tab(1).creation_date           -- �����Z�b�g����.�쐬��
     ,l_in_msa_tab(1).created_by              -- �����Z�b�g����.�쐬��
     ,l_in_msa_tab(1).organization_id         -- �����Z�b�g����.�g�DID
     ,l_in_msa_tab(1).customer_id             -- �����Z�b�g����.Customer_Id
     ,l_in_msa_tab(1).ship_to_site_id         -- �����Z�b�g����.Ship_To_Site_Id
     ,l_in_msa_tab(1).category_id             -- �����Z�b�g����.Category_Id
     ,l_in_msa_tab(1).category_set_id         -- �����Z�b�g����.Category_Set_Id
     ,l_in_msa_tab(1).inventory_item_id       -- �����Z�b�g����.�i��ID
     ,l_in_msa_tab(1).secondary_inventory     -- �����Z�b�g����.Secondary_Inventory
     ,l_in_msa_tab(1).attribute_category      -- �����Z�b�g����.�����Z�b�g�敪
     ,l_in_msa_tab(1).attribute1              -- �����Z�b�g����.�J�n�����N����(DFF1)
     ,l_in_msa_tab(1).attribute2              -- �����Z�b�g����.�L���J�n��(DFF2)
     ,l_in_msa_tab(1).attribute3              -- �����Z�b�g����.�L���I����(DFF3)
     ,l_in_msa_tab(1).attribute4              -- �����Z�b�g����.�ݒ萔��(DFF4)
     ,l_in_msa_tab(1).attribute5              -- �����Z�b�g����.�ړ���(DFF5)
     ,l_in_msa_tab(1).attribute6              -- �����Z�b�g����.DFF6
     ,l_in_msa_tab(1).attribute7              -- �����Z�b�g����.DFF7
     ,l_in_msa_tab(1).attribute8              -- �����Z�b�g����.DFF8
     ,l_in_msa_tab(1).attribute9              -- �����Z�b�g����.DFF9
     ,l_in_msa_tab(1).attribute10             -- �����Z�b�g����.DFF10
     ,l_in_msa_tab(1).attribute11             -- �����Z�b�g����.DFF11
     ,l_in_msa_tab(1).attribute12             -- �����Z�b�g����.DFF12
     ,l_in_msa_tab(1).attribute13             -- �����Z�b�g����.DFF13
     ,l_in_msa_tab(1).attribute14             -- �����Z�b�g����.DFF14
     ,l_in_msa_tab(1).attribute15             -- �����Z�b�g����.DFF15
    ;
--
    -- �Ώۃf�[�^�����݂���ꍇ
    IF ( l_assignments_set_cur%FOUND ) THEN
      -- ===============================================
      -- �����Z�b�g�EAPI�W�����R�[�h�^�C�v�̏���
      -- ===============================================
      l_in_mas_rec.operation             := cv_operation_update;      -- �����Z�b�g�w�b�_.�����敪(UPDATE)
      l_in_mas_rec.last_update_date      := cd_last_update_date;      -- �����Z�b�g�w�b�_.�ŏI�X�V��
      l_in_mas_rec.last_updated_by       := cn_last_updated_by;       -- �����Z�b�g�w�b�_.�ŏI�X�V��
      l_in_mas_rec.last_update_login     := cn_last_update_login;     -- �����Z�b�g�w�b�_.�ŏI�X�V���O�C��
--
      -- ===============================================
      -- �ړ����̌v�Z
      -- ===============================================
      ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) + in_quantity;
--
      -- ===============================================
      -- �����Z�b�g����PLSQL�\�̏���
      -- ===============================================
      l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );   -- �����Z�b�g����.�ړ���(DFF5)
      l_in_msa_tab(1).operation          := cv_operation_update;      -- �����Z�b�g����.�����敪(UPDATE)
      l_in_msa_tab(1).last_update_date   := cd_last_update_date;      -- �����Z�b�g����.�ŏI�X�V��
      l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;       -- �����Z�b�g����.�ŏI�X�V��
      l_in_msa_tab(1).last_update_login  := cn_last_update_login;     -- �����Z�b�g����.�ŏI�X�V���O�C��
--
      -- ===============================================
      -- �����Z�b�g�w�b�_/���ׂ̍X�V�iAPI�N���j
      -- ===============================================
      mrp_src_assignment_pub.process_assignment(
         p_api_version_number          => cv_api_version
        ,p_init_msg_list               => FND_API.G_TRUE
        ,p_return_values               => FND_API.G_TRUE
        ,p_commit                      => FND_API.G_FALSE
        ,x_return_status               => lv_return_status
        ,x_msg_count                   => ln_msg_count
        ,x_msg_data                    => lv_msg_data
        ,p_Assignment_Set_rec          => l_in_mas_rec
        ,p_Assignment_Set_val_rec      => l_mas_val_rec
        ,p_Assignment_tbl              => l_in_msa_tab
        ,p_Assignment_val_tbl          => l_msa_val_tab
        ,x_Assignment_Set_rec          => l_out_mas_rec
        ,x_Assignment_Set_val_rec      => l_out_mas_val_rec
        ,x_Assignment_tbl              => l_out_msa_tab
        ,x_Assignment_val_tbl          => l_out_msa_val_tab
      );
--
      -- �G���[�����������ꍇ
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        ov_errmsg := lv_msg_data;
        RAISE api_expt;
      END IF;
--
      -- �ړ������O�����ƂȂ����ꍇ�͌x���I������
      IF ( l_in_msa_tab(1).attribute5 < 0 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    CLOSE l_assignments_set_cur;
--
  EXCEPTION
    -- API�N���ŃG���[
    WHEN api_expt THEN
      IF ( l_assignments_set_cur%ISOPEN ) THEN
        CLOSE l_assignments_set_cur;
      END IF;
      ov_retcode       := cv_status_error;
    -- ���̑���O�G���[
    WHEN OTHERS THEN
      IF ( l_assignments_set_cur%ISOPEN ) THEN
        CLOSE l_assignments_set_cur;
      END IF;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END upd_assignment;
  --
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : �q�ɏ��擾����
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    iv_organization_code    IN  VARCHAR2,     -- �g�D�R�[�h
    ov_loct_code            OUT VARCHAR2,     -- �q�ɃR�[�h
    ov_loct_name            OUT VARCHAR2,     -- �q�ɖ�
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_loct_info'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_del_mark_n  CONSTANT NUMBER        := 0;                        -- �L��
--
    -- *** ���[�J���ϐ� ***
    lv_loct_code ic_loct_mst.location%TYPE;
    lv_loct_name ic_loct_mst.loct_desc%TYPE;
    lv_whse_code ic_loct_mst.whse_code%TYPE;
    ln_rec_cnt NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --==============================================================
    --�q�ɃR�[�h�擾
    --==============================================================
    SELECT MIN(ilm.location)                   --  �ۊǑq�ɃR�[�h�i�ŏ��l�j
          ,MIN(ilm.whse_code)                  --  OPM�q�ɃR�[�h�i�ŏ��l�j
          ,COUNT(ilm.location)                 --  �q�ɃR�[�h�i�Ώۃ��R�[�h���j
    INTO   lv_loct_code
          ,lv_whse_code
          ,ln_rec_cnt
    FROM   ic_loct_mst                 ilm     --  OPM�ۊǃ}�X�^
    WHERE  ilm.whse_code   = iv_organization_code
    AND    ilm.delete_mark = cn_del_mark_n
    ;
    --==============================================================
    --�Ώۃ��R�[�h��������
    --==============================================================
    IF ln_rec_cnt = 0 then
      RAISE NO_DATA_FOUND;
    End IF;
    --
    --==============================================================
    --�q�ɖ��擾
    --==============================================================
    SELECT ilm.loct_desc                       --  �q�ɖ�
    INTO   lv_loct_name
    FROM   ic_loct_mst                 ilm      --  OPM�ۊǃ}�X�^
    WHERE  ilm.location  = lv_loct_code
    AND    ilm.whse_code = lv_whse_code
    ;
    --
    ov_loct_code := lv_loct_code;
    ov_loct_name := lv_loct_name;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode   := cv_status_warn;
      ov_errbuf    := NULL;
      ov_errmsg    := NULL;
      ov_loct_code := NULL;
      ov_loct_name := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
      ov_loct_code := NULL;
      ov_loct_name := NULL;
  END get_loct_info;
  --
END XXCOP_COMMON_PKG2;
/
