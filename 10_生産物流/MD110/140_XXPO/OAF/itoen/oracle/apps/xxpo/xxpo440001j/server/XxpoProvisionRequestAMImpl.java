/*============================================================================
* �t�@�C���� : XxpoProvisionRequestAMImpl
* �T�v����   : �x���˗��v��A�v���P�[�V�������W���[��
* �o�[�W���� : 1.12
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  ��r���     �V�K�쐬
* 2008-06-06 1.0  ��r���     �����ύX�v��#137�Ή�
* 2008-06-17 1.1  ��r���     ST�s�#126�Ή�
* 2008-06-18 1.2  ��r���     �s��Ή�
* 2008-06-02 1.3  ��r���     �ύX�v��#42�Ή�
*                              ST�s�#199�Ή�
* 2008-07-04 1.4  ��r���     �ύX�v��#91�Ή�
* 2008-07-29 1.5  ��r���     �����ύX�v��#164,166,173�A�ۑ�#32
* 2008-08-13 1.6  ��r���     ST�s�#249�Ή�
* 2008-08-27 1.7  �ɓ��ЂƂ�   �����ύX�v��#209�Ή�
* 2008-10-07 1.8  �ɓ��ЂƂ�   �����e�X�g�w�E240�Ή�
* 2008-10-21 1.9  ��r���     T_S_437�Ή�
*                              T_TE080_BPO_440 No14
* 2008-10-27 1.10 ��r���     T_TE080_BPO_600 No22
* 2009-01-05 1.11 ��r���     �{�ԏ�Q#861�Ή�
* 2009-01-20 1.12 �g������     �{�ԏ�Q#739,985�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.AttributeDef;
import oracle.jbo.RowSetIterator;
/***************************************************************************
 * �x���˗��v���ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.11
 ***************************************************************************
 */
public class XxpoProvisionRequestAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRequestAMImpl()
  {
  }

  /***************************************************************************
   * �x���w���v���ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // �x���˗��v�񌟍�VO
    XxpoProvSearchVOImpl vo = getXxpoProvSearchVO1();
    OARow row = null;
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey",  new Number(1));
      row.setAttribute("ExeType", exeType);

      //�v���t�@�C�������\���i�\ID�擾
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // ��\���i�\���擾�ł��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      row.setAttribute("RepPriceListId", repPriceListId);

    } else
    {
      row = (OARow)vo.first();
    }
    // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
    if (XxpoConstants.EXE_TYPE_12.equals(exeType)
     && XxcmnUtility.isBlankOrNull(row.getAttribute("VendorId")))
    {
      // ���[�U�[���擾 
      HashMap userInfo = XxpoUtility.getProvUserData(getOADBTransaction());
      // �d����ɒl��ݒ�
      row.setAttribute("VendorId",     userInfo.get("VendorId"));
      row.setAttribute("VendorCode",   userInfo.get("VendorCode"));
      row.setAttribute("VendorName",   userInfo.get("VendorName"));

    }

    // �x���˗��v��PVO
    XxpoProvisionRequestPVOImpl pvo = getXxpoProvisionRequestPVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      OARow prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // ���i�ݒ�{�^���E��̃{�^���E�蓮�w���m��{�^��������
        prow.setAttribute("PriceSetBtnReject",   Boolean.FALSE); // ���i�ݒ�{�^��
        prow.setAttribute("RcvBtnReject",        Boolean.FALSE); // ��̃{�^��
        prow.setAttribute("ManualFixBtnReject",  Boolean.FALSE); // �蓮�w���m��{�^��
      } else 
      {
        // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
        if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
        {
          // ��̃{�^���E�蓮�w���m��{�^�������s��  
          prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // ��̃{�^��
          prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // �蓮�w���m��{�^��
          prow.setAttribute("CopyBtnReject",       Boolean.TRUE); // �R�s�[�{�^��
          
        } else
        {
          // ��̃{�^���E�蓮�w���m��{�^�������\  
          prow.setAttribute("RcvBtnReject",        Boolean.FALSE); // ��̃{�^��
          prow.setAttribute("ManualFixBtnReject",  Boolean.FALSE); // �蓮�w���m��{�^��

        }
        // ���i�ݒ�{�^�������s��
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        // ���z�m��{�^�������s��
        prow.setAttribute("AmountFixBtnReject", Boolean.TRUE); // ���z�m��{�^��

      }
    }
  } // initializeList

  /***************************************************************************
   * �x���w���v���ʂ̌����������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchList() throws OAException
  {
    // �x���w������VO�擾
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();

    // ���������ݒ�
    OARow shRow = (OARow)svo.first();
    HashMap shParams = new HashMap();
    shParams.put("orderType",    shRow.getAttribute("OrderType"));       // �����敪
    shParams.put("vendorCode",   shRow.getAttribute("VendorCode"));      // �����
    shParams.put("shipToCode",   shRow.getAttribute("ShipToCode"));      // �z����
    shParams.put("reqNo",        shRow.getAttribute("ReqNo"));           // �˗�No
    shParams.put("shipToNo",     shRow.getAttribute("ShipToNo"));        // �z��No
    shParams.put("transStatus",  shRow.getAttribute("TransStatusCode")); // �X�e�[�^�X
    shParams.put("notifStatus",  shRow.getAttribute("NotifStatusCode")); // �ʒm�X�e�[�^�X
    shParams.put("shipDateFrom", shRow.getAttribute("ShipDateFrom"));    // �o�ɓ�From
    shParams.put("shipDateTo",   shRow.getAttribute("ShipDateTo"));      // �o�ɓ�To
    shParams.put("arvlDateFrom", shRow.getAttribute("ArvlDateFrom"));    // ���ɓ�From
    shParams.put("arvlDateTo",   shRow.getAttribute("ArvlDateTo"));      // ���ɓ�To
    shParams.put("reqDeptCode",  shRow.getAttribute("ReqDeptCode"));     // �˗�����
    shParams.put("instDeptCode", shRow.getAttribute("InstDeptCode"));    // �w������
    shParams.put("shipWhseCode", shRow.getAttribute("ShipWhseCode"));    // �o�ɑq��
    shParams.put("exeType",      shRow.getAttribute("ExeType"));         // �N���^�C�v
    shParams.put("baseReqNo",    shRow.getAttribute("BaseReqNo"));       // ���˗�No

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // ���������s���܂��B
    vo.initQuery(shParams);

  } // doSearchList

  /***************************************************************************
   * �x���w���v���ʂ̊m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �m�菈���`�F�b�N
      chkFix(vo, row, exceptions);

    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      // �X�e�[�^�X���u���͊����v�ɍX�V���܂��B
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_NRK);
      exeFlag = true;
    }
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      doCommitList();
      // �m�菈���������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_FIX);
    }
  } // doFixList

  /***************************************************************************
   * �y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // �����Ώۂ��擾���܂��B
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // �`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
    if ((rows != null) || (rows.length != 0)) 
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * ���I���`�F�b�N���s�����\�b�h�ł��B
   * @param rows - �s�I�u�W�F�N�g�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkNonChoice(
    Row[] rows
    ) throws OAException
  {
    // ���I���`�F�b�N���s���܂��B
    if ((rows == null) || (rows.length == 0)) 
    {
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10144);
    }
  } // chkNonChoice

  /***************************************************************************
   * �x���w���v���ʂ̎�̏������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doRcvList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // ��̏����`�F�b�N
      chkRcv(vo, row, exceptions);

    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      // �X�e�[�^�X���u��̍ρv�ɍX�V���܂��B
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_ZRZ);
      String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // ���������쐬�敪
      // ���������쐬�敪���u�Ώہv�̏ꍇ
      if ("1".equals(autoCreatePoClass)) 
      {
        String reqNo = (String)row.getAttribute("RequestNo"); // �˗�No
        // ���������쐬�����s
        XxpoUtility.provAutoPurchaseOrders(getOADBTransaction(), reqNo);
// 2009-01-05 D.Nihei Del Start
//        // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�ɍX�V���܂��B
//        XxpoUtility.updateNotifStatus(
//          getOADBTransaction(),
//          orderHeaderId,
//          XxpoConstants.NOTIF_STATUS_KTZ);
// 2009-01-05 D.Nihei Del End

      }
      exeFlag = true;
    }
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      doCommitList();
      // ��̏����������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_RCV);

    }
  } // doRcvList

  /***************************************************************************
   * �x���w���v���ʂ̎蓮�w���m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doManualFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �蓮�w���m�菈���`�F�b�N
      chkManualFix(vo, row, exceptions, true);
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�ɍX�V���܂��B
      XxpoUtility.updateNotifStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.NOTIF_STATUS_KTZ);
      exeFlag = true;
    }
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      doCommitList();
      // �蓮�w���m�菈���������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_MANUAL_FIX);

    }
  } // doManualFixList

  /***************************************************************************
   * �x���w���v���ʂ̉��i�ݒ菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doPriceSetList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // ���i�ݒ菈���`�F�b�N
      chkPriceSet(vo, row, exceptions, true);
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    //�x���w���v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    // ��\���i�\�擾
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId");          
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      // ���i�ݒ菈�������s���܂��B
      String listIdVendor = (String)row.getAttribute("ListHeaderIdVendor"); // ����承�i�\ID
      Date arrivalDate    = (Date)row.getAttribute("ArrivalDate");          // ���ɓ�
      //�P���X�V�������s
      String errItemNo = XxpoUtility.updateUnitPrice(
                           getOADBTransaction(),
                           orderHeaderId,
                           listIdVendor,
                           listIdRepresent,
                           arrivalDate,
                           null,
                           null,
                           null
                         );
      // �G���[�i��No�������Ă����ꍇ
      if (!XxcmnUtility.isBlankOrNull(errItemNo)) 
      {
        Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM,
                                                   errItemNo) };
        // ���i�ݒ�G���[
        throw new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    vo.getName(),
                    row.getKey(),
                    "OrderTypeId",
                    orderType,
                    XxcmnConstants.APPL_XXPO,
                    XxpoConstants.XXPO10200,
                    tokens);
            
      }
      exeFlag = true;
    }
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      doCommitList();
      // ���i�ݒ菈���������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_PRICE_SET);
    }
  } // doPriceSetList

  /***************************************************************************
   * �x���w���v���ʂ̋��z�m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doAmountFixList() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w������VO�擾
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �L�����z�m�菈���`�F�b�N
      chkAmountFix(vo, row, exceptions);
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

// 2009-01-20 v1.12 T.Yoshimoto Add Start �{��#985
      Date updateArrivalDate = getUpdateArrivalDate(row);

      XxpoUtility.updArrivalDate(
        getOADBTransaction(),
        orderHeaderId,
        updateArrivalDate);
// 2009-01-20 v1.12 T.Yoshimoto Add End �{��#985

      // �L�����z�m�菈�������s���܂��B
      XxpoUtility.updateFixClass(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.FIX_CLASS_ON);
      exeFlag = true;
    }
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      doCommitList();
      // ���z�m�菈���������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_AMOUNT_FIX);
    }
  } // doAmountFixList

  /***************************************************************************
   * �x���w���v���ʂ̃R�~�b�g�E�Č����������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doCommitList()
  {
    // �R�~�b�g���s
    XxpoUtility.commit(getOADBTransaction());
    // �Č������s���܂��B
    doSearchList();

  } // doCommitList

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param reqNo   - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    ) throws OAException
  {
    // �x���˗��v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey",  new Number(1));
      srow.setAttribute("ExeType", exeType);
      //�v���t�@�C�������\���i�\ID�擾
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // ��\���i�\���擾�ł��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      srow.setAttribute("RepPriceListId", repPriceListId);
    }
    // �x���w���쐬�w�b�_PVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));

    } else
    {
      prow = (OARow)pvo.first();
      // ������
      handleEventAllOnHdr(prow);

    }

    OARow row  = null;
    // �V�K�̏ꍇ
    if (XxcmnUtility.isBlankOrNull(reqNo)) 
    {
      // �x���w���쐬�w�b�_VO�擾
      XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
      if (vo.getFetchedRowCount() == 0)
      {
        vo.setMaxFetchSize(0);
        vo.executeQuery();
        vo.insertRow(vo.createRow());
        row = (OARow)vo.first();
        row.setNewRowState(OARow.STATUS_INITIALIZED);
      } else
      {
        row = (OARow)vo.first();
      }
      // �L�[�̐ݒ�
      row.setAttribute("OrderHeaderId", new Number(-1));
      // �f�t�H���g�l�̐ݒ�
      row.setAttribute("NewFlag",             XxcmnConstants.STRING_Y);              // �V�K�t���O
      row.setAttribute("TransStatus",         XxpoConstants.PROV_STATUS_NRT);        // �X�e�[�^�X
      row.setAttribute("NotifStatus",         XxpoConstants.NOTIF_STATUS_MTT);       // �ʒm�X�e�[�^�X
      row.setAttribute("WeightCapacityClass", XxpoConstants.WGHT_CAPA_CLASS_WEIGHT); // �d�ʗe�ϋ敪
      row.setAttribute("RcvClass",            XxpoConstants.RCV_CLASS_OFF);          // �w�����
      row.setAttribute("FixClass",            XxpoConstants.FIX_CLASS_OFF);          // ���z�m��

      // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // �ΏۊO�ɐݒ�
        row.setAttribute("FreightChargeClass",  XxcmnConstants.OBJECT_OFF); // �^���敪

      // ��L�ȊO
      } else 
      {
        // �Ώۂɐݒ�
        row.setAttribute("FreightChargeClass",  XxcmnConstants.OBJECT_ON); // �^���敪

      }
        
      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // ���[�U�[���擾 
        HashMap userInfo = XxpoUtility.getProvUserData(getOADBTransaction());
        // �d����E�ڋq�ɒl��ݒ�
        row.setAttribute("VendorId",     userInfo.get("VendorId"));
        row.setAttribute("VendorCode",   userInfo.get("VendorCode"));
        row.setAttribute("VendorName",   userInfo.get("VendorName"));
        row.setAttribute("CustomerId",   userInfo.get("CustomerId"));
        row.setAttribute("CustomerCode", userInfo.get("CustomerCode"));
        row.setAttribute("PriceList",    userInfo.get("PriceList"));

      }

      // �V�K�����ڐ���
      handleEventInsHdr(exeType, prow, row);

    // �X�V�̏ꍇ
    } else 
    {
      // �˗�No�Ō��������s
      doSearchHdr(reqNo);

      // �x���w���쐬�w�b�_VO�擾
      XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
      row = (OARow)vo.first();

      // �X�V�����ڐ���
      handleEventUpdHdr(exeType, prow, row);

    }

    // ���׍s�̌���
    doSearchLine(exeType);

  } // initializeHdr
  
  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̐V�K���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param prow    - PVO�s�N���X
   * @param row     - VO�s�N���X
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void handleEventInsHdr(
    String exeType,
    OARow prow,
    OARow row
    ) throws OAException
  {
    // ���ʃ{�^������
    prow.setAttribute("FixBtnReject",        Boolean.TRUE); // �m��{�^��
    prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // ��̃{�^��
    prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // �蓮�w���m��{�^��
    prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
    prow.setAttribute("PriceSetBtnReject",   Boolean.TRUE); // ���i�ݒ�{�^��
    // ���ʍ��ڐ���
    prow.setAttribute("FixReadOnly", Boolean.TRUE); // ���z�m��

    // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
    if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // �Ȃ�

    // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
    } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
    {
      // ���ڐ���
      prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
      prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�

    // �N���^�C�v���u13�F���m�u���p�v�̏ꍇ
    } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
    {
      // �Ȃ�

    // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
    } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
    {
      // ���ڐ���
      prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
      prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

    }
  } // handleEventInsHdr

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̍X�V���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param prow    - PVO�s�N���X
   * @param row     - VO�s�N���X
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void handleEventUpdHdr(
    String exeType,
    OARow prow,
    OARow row
    ) throws OAException
  {
    // ������
    handleEventAllOnHdr(prow);
    // �X�e�[�^�X���擾
    String transStatus = (String)row.getAttribute("TransStatus");
    // �X�e�[�^�X���ʍ��ڐ���
    prow.setAttribute("WeightCapacityReadOnly" , Boolean.TRUE);                  // �d�ʗe�ϋ敪
    prow.setAttribute("InstDeptRequired"       , XxcmnConstants.STRING_UI_ONLY); // �w������
    prow.setAttribute("ShippedDateRequired"    , XxcmnConstants.STRING_UI_ONLY); // �o�ɓ�

    String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // �^���敪
    if (XxcmnConstants.OBJECT_ON.equals(freightChargeClass)) 
    {
      prow.setAttribute("FreightCarrierRequired" , XxcmnConstants.STRING_UI_ONLY); // �^���Ǝ�
    }

    // �X�e�[�^�X���u���͒��v�̏ꍇ 
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      // ���ʃ{�^������
      prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // ��̃{�^��
      prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // �蓮�w���m��{�^��

      // ���ʍ��ڐ���
      prow.setAttribute("FixReadOnly",            Boolean.TRUE); // ���z�m��

      // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // �Ȃ�

      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        // ���ڐ���
        prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�

      // �N���^�C�v���u13�F���m�u���p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��

      // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

      }

    // �X�e�[�^�X���u���͊����v�̏ꍇ 
    } else if (XxpoConstants.PROV_STATUS_NRK.equals(transStatus))
    {
      // ���ʃ{�^������
      prow.setAttribute("FixBtnReject",        Boolean.TRUE); // �m��{�^��
      prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // �蓮�w���m��{�^��

      // ���ʍ��ڐ���
      prow.setAttribute("FixReadOnly",            Boolean.TRUE); // ���z�m��

      // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // �Ȃ�

      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("RcvBtnReject",      Boolean.TRUE); // ��̃{�^��
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        // ���ڐ���
        prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�

      // �N���^�C�v���u13�F���m�u���p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��

      // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        // ���ڐ���
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

      }
    
    // �X�e�[�^�X���u��̍ρv�̏ꍇ 
    } else if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // ��̃^�C�v�擾
      String rcvType = (String)row.getAttribute("RcvType");
      // ���ʃ{�^������
      prow.setAttribute("FixBtnReject",        Boolean.TRUE); // �m��{�^��
      prow.setAttribute("RcvBtnReject",        Boolean.TRUE); // ��̃{�^��
      // ���ʍ��ڐ���
      prow.setAttribute("OrderTypeReadOnly",  Boolean.TRUE); // �����敪
      prow.setAttribute("FixReadOnly",        Boolean.TRUE); // ���z�m��

      // �ʒm�X�e�[�^���擾���܂��B
      String notifStatus = (String)row.getAttribute("NotifStatus");    // �ʒm�X�e�[�^�X
      // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�̏ꍇ
      if (XxpoConstants.NOTIF_STATUS_KTZ.equals(notifStatus))
      {
        // �{�^������
        prow.setAttribute("ManualFixBtnReject",  Boolean.TRUE); // �蓮�w���m��{�^��
      }

      // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {

        // ��̃^�C�v���u5�F�ꕔ���їL�v�̏ꍇ
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // �z����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // ���ɓ�
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪
          
        // ��̃^�C�v���u4�F�z�ԍρE�����L�v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_4.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪
          
        // ��̃^�C�v���u3�F�z�ԍρE�������v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_3.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

        // ��̃^�C�v���u2�F�����L�v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�

        // ��̃^�C�v���u1�F�����ρv�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_1.equals(rcvType))
        {
          // ���ڐ���
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // �z����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // ���ɓ�

        // ��̃^�C�v���u0�F�������v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_0.equals(rcvType))
        {
          // �Ȃ�
        } else
        {
          // �z��O�̂��ߎQ�Ƃ̂�
          handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start �����ύX�v��#209 �o�׎��ьv��ς̏ꍇ�ȂǁA���׉�ʂ֑J�ڂł��Ȃ��Ȃ�̂ŁA
//   handleEventAllOffHdr���Ŏ��փ{�^����������Ȃ��ŉ������B
          prow.setAttribute("NextBtnReject", Boolean.TRUE); // ���փ{�^��
// 2008-08-27 H.Itou Add End
        }

      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // �Q�Ƃ̂�
        handleEventAllOffHdr(prow);

      // �N���^�C�v���u13�F���m�u���p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_13.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject", Boolean.TRUE); // ���i�ݒ�{�^��
        // ���ڐ���
        prow.setAttribute("ReqDeptReadOnly", Boolean.TRUE); // �˗�����

        // ��̃^�C�v���u5�F�ꕔ���їL�v�̏ꍇ
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // �z����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // ���ɓ�
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪
          
        // ��̃^�C�v���u4�F�z�ԍρE�����L�v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_4.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

        // ��̃^�C�v���u3�F�z�ԍρE�������v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_3.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

        // ��̃^�C�v���u2�F�����L�v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
        }
      // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // �{�^������
        prow.setAttribute("PriceSetBtnReject",      Boolean.TRUE); // ���i�ݒ�{�^��
        // ���ڐ���
        prow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE); // �^���Ǝ�
        prow.setAttribute("FreightChargeReadOnly",  Boolean.TRUE); // �^���敪

        // ��̃^�C�v���u5�F�ꕔ���їL�v�̏ꍇ
        if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // �z����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // ���ɓ�
          
        // ��̃^�C�v���u2�F�����L�v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_2.equals(rcvType))
        {
          // �{�^������
          prow.setAttribute("ProvCancelBtnReject",    Boolean.TRUE); // �x������{�^��
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�

        // ��̃^�C�v���u1�F�����ρv�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_1.equals(rcvType))
        {
          // ���ڐ���
          prow.setAttribute("ReqDeptReadOnly",        Boolean.TRUE); // �˗�����
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����
          prow.setAttribute("ShipToReadOnly",         Boolean.TRUE); // �z����
          prow.setAttribute("ShipWhseReadOnly",       Boolean.TRUE); // �o�ɑq��
          prow.setAttribute("ShippedDateReadOnly",    Boolean.TRUE); // �o�ɓ�
          prow.setAttribute("ArrivalDateReadOnly",    Boolean.TRUE); // ���ɓ�

        // ��̃^�C�v���u0�F�������v�̏ꍇ
        } else if (XxpoConstants.RCV_TYPE_0.equals(rcvType))
        {
          // ���ڐ���
          prow.setAttribute("VendorReadOnly",         Boolean.TRUE); // �����

        } else
        {
          // �z��O�̂��ߎQ�Ƃ̂�
          handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start �����ύX�v��#209 �o�׎��ьv��ς̏ꍇ�ȂǁA���׉�ʂ֑J�ڂł��Ȃ��Ȃ�̂ŁA
//   handleEventAllOffHdr���Ŏ��փ{�^����������Ȃ��ŉ������B
          prow.setAttribute("NextBtnReject", Boolean.TRUE); // ���փ{�^��
// 2008-08-27 H.Itou Add End

        }
      }
    // �X�e�[�^�X���u�o�׎��ьv��ρv�̏ꍇ 
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);

      // �N���^�C�v���u11�F�ɓ����p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // ���ڐ���
        prow.setAttribute("FixReadOnly", Boolean.FALSE); // ���z�m��

        // ���z�m��t���O���擾
        String fixClass = (String)row.getAttribute("FixClass"); 
        // ���z���m��
        if (XxpoConstants.FIX_CLASS_OFF.equals(fixClass)) 
        {
          // �{�^������
          prow.setAttribute("PriceSetBtnReject", Boolean.FALSE); // ���i�ݒ�{�^��
          // ���ڐ���
          prow.setAttribute("InstDeptReadOnly",  Boolean.FALSE); // �w������
            
        }
      }
    }
  } // handleEventUpdHdr

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̍��ڂ�S��TRUE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
// �o�׎��ьv��ς̏ꍇ�ȂǁA���׉�ʂ֑J�ڂł��Ȃ��Ȃ�̂ŁA
//   handleEventAllOffHdr���Ŏ��փ{�^����������Ȃ��ŉ������B
    prow.setAttribute("FixBtnReject"                 , Boolean.TRUE); // �m��{�^��
    prow.setAttribute("RcvBtnReject"                 , Boolean.TRUE); // ��̃{�^��
    prow.setAttribute("ManualFixBtnReject"           , Boolean.TRUE); // �蓮�w���m��{�^��
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.TRUE); // �x������{�^��
    prow.setAttribute("PriceSetBtnReject"            , Boolean.TRUE); // ���i�ݒ�{�^��
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.TRUE); // �����敪
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.TRUE); // �d�ʗe�ϋ敪
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.TRUE); // �˗�����
    prow.setAttribute("VendorReadOnly"               , Boolean.TRUE); // �����
    prow.setAttribute("ShipToReadOnly"               , Boolean.TRUE); // �z����
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.TRUE); // �o�ɑq��
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.TRUE); // �^���Ǝ�
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.TRUE); // �o�ɓ�
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.TRUE); // ���ɓ�
    prow.setAttribute("ArrivalTimeFromReadOnly"      , Boolean.TRUE); // ���׎���From
    prow.setAttribute("ArrivalTimeToReadOnly"        , Boolean.TRUE); // ���׎���To
    prow.setAttribute("FreightChargeReadOnly"        , Boolean.TRUE); // �^���敪
    prow.setAttribute("TakebackReadOnly"             , Boolean.TRUE); // ����敪
    prow.setAttribute("DesignatedProdDateReadOnly"   , Boolean.TRUE); // ������
    prow.setAttribute("DesignatedItemReadOnly"       , Boolean.TRUE); // �����i��
    prow.setAttribute("DesignatedBranchNoReadOnly"   , Boolean.TRUE); // �����ԍ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // �E�v
    prow.setAttribute("FixReadOnly"                  , Boolean.TRUE); // ���z�m��
    prow.setAttribute("InstDeptReadOnly"             , Boolean.TRUE); // �w������

  } // handleEventAllOffHdr

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("FixBtnReject"                 , Boolean.FALSE); // �m��{�^��
    prow.setAttribute("RcvBtnReject"                 , Boolean.FALSE); // ��̃{�^��
    prow.setAttribute("ManualFixBtnReject"           , Boolean.FALSE); // �蓮�w���m��{�^��
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.FALSE); // �x������{�^��
    prow.setAttribute("PriceSetBtnReject"            , Boolean.FALSE); // ���i�ݒ�{�^��
    prow.setAttribute("OrderTypeReadOnly"            , Boolean.FALSE); // �����敪
    prow.setAttribute("WeightCapacityReadOnly"       , Boolean.FALSE); // �d�ʗe�ϋ敪
    prow.setAttribute("ReqDeptReadOnly"              , Boolean.FALSE); // �˗�����
    prow.setAttribute("VendorReadOnly"               , Boolean.FALSE); // �����
    prow.setAttribute("ShipToReadOnly"               , Boolean.FALSE); // �z����
    prow.setAttribute("ShipWhseReadOnly"             , Boolean.FALSE); // �o�ɑq��
    prow.setAttribute("FreightCarrierReadOnly"       , Boolean.FALSE); // �^���Ǝ�
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.FALSE); // �o�ɓ�
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.FALSE); // ���ɓ�
    prow.setAttribute("ArrivalTimeFromReadOnly"      , Boolean.FALSE); // ���׎���From
    prow.setAttribute("ArrivalTimeToReadOnly"        , Boolean.FALSE); // ���׎���To
    prow.setAttribute("FreightChargeReadOnly"        , Boolean.FALSE); // �^���敪
    prow.setAttribute("TakebackReadOnly"             , Boolean.FALSE); // ����敪
    prow.setAttribute("DesignatedProdDateReadOnly"   , Boolean.FALSE); // ������
    prow.setAttribute("DesignatedItemReadOnly"       , Boolean.FALSE); // �����i��
    prow.setAttribute("DesignatedBranchNoReadOnly"   , Boolean.FALSE); // �����ԍ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // �E�v
    prow.setAttribute("FixReadOnly"                  , Boolean.FALSE); // ���z�m��
    prow.setAttribute("InstDeptReadOnly"             , Boolean.FALSE); // �w������
    prow.setAttribute("InstDeptRequired"             , XxcmnConstants.STRING_NO); // �w������
    prow.setAttribute("FreightCarrierRequired"       , XxcmnConstants.STRING_NO); // �^���Ǝ�
    prow.setAttribute("ShippedDateRequired"          , XxcmnConstants.STRING_NO); // �o�ɓ�

  } // handleEventAllOnHdr

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̌����������s�����\�b�h�ł��B
   * @param  reqNo - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    // ���������s���܂��B
    vo.initQuery(reqNo);
    vo.first();
    // �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // �x���w���쐬PVO
      XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
// 2008-08-27 H.Itou Add Start �����ύX�v��#209 �o�׎��ьv��ς̏ꍇ�ȂǁA���׉�ʂ֑J�ڂł��Ȃ��Ȃ�̂ŁA
//   handleEventAllOffHdr���Ŏ��փ{�^����������Ȃ��ŉ������B
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // ���փ{�^��
// 2008-08-27 H.Itou Add End
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);

    }
  } // doSearchHdr

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̊m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doFix() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // �m�菈���`�F�b�N
    chkFix(vo, row, exceptions);
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // �r���`�F�b�N
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo     = (String)row.getAttribute("RequestNo");     // �˗�No
    // �X�e�[�^�X���u���͊����v�ɍX�V���܂��B
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_NRK);

    // �R�~�b�g���s
    doCommit(requestNo);
    // �m�菈���������b�Z�[�W��\��
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_FIX);

  } // doFix

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̎�̏������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doRcv() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // ��̏����`�F�b�N
    chkRcv(vo, row, exceptions);
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // �r���`�F�b�N
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo     = (String)row.getAttribute("RequestNo");     // �˗�No
    // �X�e�[�^�X���u��̍ρv�ɍX�V���܂��B
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_ZRZ);
    String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // ���������쐬�敪
    // ���������쐬�敪���u�Ώہv�̏ꍇ
    if ("1".equals(autoCreatePoClass)) 
    {
      // ���������쐬�����s
      String reqNo = (String)row.getAttribute("RequestNo"); // �˗�No
      // ���������쐬�����s
      XxpoUtility.provAutoPurchaseOrders(getOADBTransaction(), reqNo);
// 2009-01-05 D.Nihei Del Start
//      // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�ɍX�V���܂��B
//      XxpoUtility.updateNotifStatus(
//        getOADBTransaction(),
//        orderHeaderId,
//        XxpoConstants.NOTIF_STATUS_KTZ);
// 2009-01-05 D.Nihei Del End

    }

    // �R�~�b�g���s
    doCommit(requestNo);
    // ��̏����������b�Z�[�W��\��
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_RCV);

  } // doRcv

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̎蓮�w���m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doManualFix() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // �蓮�w���m��`�F�b�N
    chkManualFix(vo, row, exceptions, false);
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    // �r���`�F�b�N
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo     = (String)row.getAttribute("RequestNo");     // �˗�No
    // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�ɍX�V���܂��B
    XxpoUtility.updateNotifStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.NOTIF_STATUS_KTZ);

    // �R�~�b�g���s
    doCommit(requestNo);
    // �蓮�w���m�萬�����b�Z�[�W��\��
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_MANUAL_FIX);
  } // doManualFix

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̉��i�ݒ菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doPriceSet() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // ���i�ݒ菈���`�F�b�N
    chkPriceSet(vo, row, exceptions, false);
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // �r���`�F�b�N
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo     = (String)row.getAttribute("RequestNo");     // �˗�No
    String listIdVendor  = (String)row.getAttribute("PriceList");     // ����承�i�\ID
    Date arrivalDate     = (Date)row.getAttribute("ArrivalDate");     // ���ɓ�
    //�x���w���v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // ��\���i�\�擾
    // ���i�ݒ菈�������s���܂��B
    String errItemNo = XxpoUtility.updateUnitPrice(
                         getOADBTransaction(),
                         orderHeaderId,
                         listIdVendor,
                         listIdRepresent,
                         arrivalDate,
                         null,
                         null,
                         null
                       );
    // �G���[�i��No�������Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(errItemNo)) 
    {
      Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
      //�g�[�N���𐶐����܂��B
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_ITEM,
                                                 errItemNo) };
      // ���i�ݒ�G���[
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO10200,
                  tokens);
            
    }

    // �R�~�b�g���s
    doCommit(requestNo);
    // ���i�ݒ菈���������b�Z�[�W��\��
    XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_PRICE_SET);

  } // doPriceSet

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̎x������������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doProvCancel() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // �r���`�F�b�N
    chkLockAndExclusive(vo, row);
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo     = (String)row.getAttribute("RequestNo");     // �˗�No
    // �X�e�[�^�X���擾
    String transStatus = (String)row.getAttribute("TransStatus");
    // �X�e�[�^�X���u��̍ρv�̏ꍇ 
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // �z�ԉ����������s
      String retCode = XxwshUtility.cancelCareersSchedile(getOADBTransaction(),
                                                          XxcmnConstants.BIZ_TYPE_PROV,
                                                          requestNo);
      // �p�����[�^�`�F�b�N�G���[�̏ꍇ
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // �\�����ʃG���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // �z�ԏ������s�̏ꍇ
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAREERS);

      }
    }
    // �X�e�[�^�X���u����v�ɍX�V���܂��B
    XxpoUtility.updateTransStatus(
      getOADBTransaction(),
      orderHeaderId,
      XxpoConstants.PROV_STATUS_CAN);

    // �R�~�b�g���s
    XxpoUtility.commit(getOADBTransaction());

  } // doProvCancel

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̎��֏������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl vo = getXxpoProvisionInstMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // ���֏����`�F�b�N
    chkNext(vo, row, exceptions);

    // ���o����
    getHdrData(vo, row);

    // �ύX�Ɋւ���x������
    doWarnAboutChanges();
  } // doNext

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeLine(String exeType)
  {
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVvo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();

    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // �V�K�t���O
    // �x���w���쐬����PVO
    XxpoProvisionInstMakeLinePVOImpl pvo = getXxpoProvisionInstMakeLinePVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // PVO�����l�ݒ�
      handleEventAllOnLine(prow);

    } else
    {
      prow = (OARow)pvo.first();

    }
    // �V�K�t���O���uN�F�X�V�v�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      handleEventUpdLine(exeType,
                         prow,
                         hdrRow);      

    // �V�K�̏ꍇ
    } else 
    {
      handleEventInsLine(exeType,
                         prow);      
      
    }
  } // initializeLine
  
  /*****************************************************************************
   * �w�肳�ꂽ�s���폜���܂��B
   * @param exeType - �N���^�C�v
   * @param orderLineNumber - ���הԍ�
   * @throws OAException - OA��O
   ****************************************************************************/
  public void doDeleteLine(
    String exeType,
    String orderLineNumber
    ) throws OAException 
  {
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // �˗�No
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // �V�K�t���O

    // �x���w���쐬����VO
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // �폜�Ώۍs���擾
    OARow row = (OARow)vo.getFirstFilteredRow("OrderLineNumber", new Number(Integer.parseInt(orderLineNumber)));
    Number orderLineId = (Number)row.getAttribute("OrderLineId"); // �󒍖��׃A�h�I��ID

    // �S�s�擾
    Row[] rows = vo.getAllRowsInRange();
    // �擾�s�̖��׌�����1�������Ȃ��ꍇ
    if ((rows == null) || (rows.length == 1)) 
    {
      Object itemNo = row.getAttribute("ItemNo");
      // �폜�s�G���[
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "ItemNo",
                  itemNo,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10152);

    }
    
    // �}���s�̏ꍇ
    if (XxcmnUtility.isBlankOrNull(orderLineId))
    {
      // �}���s�폜
      row.remove();

// 2008-10-21 D.Nihei DEL START
//      // �R�~�b�g����
//      doCommit(reqNo);
// 2008-10-21 D.Nihei DEL END

      // �폜�����������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    // �X�V�s�̏ꍇ
    } else
    {
      // �폜�`�F�b�N����
      chkOrderLineDel(vo, hdrRow, row);

      // �r���`�F�b�N
      chkLockAndExclusive(hdrVo, hdrRow);

      // �폜����
      XxpoUtility.deleteOrderLine(getOADBTransaction(), orderLineId);

      // �z�Ԋ֘A���ݒ�
      setCarriersData(hdrRow);

      // �e����擾
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      String sumQuantity   = (String)hdrRow.getAttribute("SumQuantity");   // ���v����
      Number smallQuantity = (Number)hdrRow.getAttribute("SmallQuantity"); // ������
      Number labelQuantity = (Number)hdrRow.getAttribute("LabelQuantity"); // ���x������
      String sumWeight     = (String)hdrRow.getAttribute("SumWeight");     // �ύڏd�ʍ��v
      String sumCapacity   = (String)hdrRow.getAttribute("SumCapacity");   // �ύڗe�ύ��v
      // �X�V����(���v���ʁA���x�������A�������A�ύڏd�ʍ��v�A�ύڗe�ύ��v)
      XxpoUtility.updateSummaryInfo(getOADBTransaction(),
                                    orderHeaderId,
                                    sumQuantity,
                                    smallQuantity,
                                    labelQuantity,
                                    sumWeight,
                                    sumCapacity);

      /******************
       * �z�ԉ�������
       ******************/
      String retCode = XxwshUtility.cancelCareersSchedile(
                         getOADBTransaction(),
                         XxcmnConstants.BIZ_TYPE_PROV,
                         reqNo);
      // �p�����[�^�`�F�b�N�G���[�̏ꍇ
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // �\�����ʃG���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // �z�ԏ������s�̏ꍇ
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }

      // �R�~�b�g����
      doCommit(reqNo);

      // �폜�����������b�Z�[�W��\��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    }
  } // doDeleteLine

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̌����������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   ***************************************************************************
   */
  public void doSearchLine(String exeType)
  {
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

    // �x���w���쐬����VO�擾
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // ���������s���܂��B
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // 1�s�����݂��Ȃ��ꍇ�A1�s�쐬
    if (vo.getFetchedRowCount() == 0) 
    {
      addRow(exeType);

    }

    // �x���w���쐬���vVO�擾
    XxpoProvisionInstMakeTotalVOImpl totalVo = getXxpoProvisionInstMakeTotalVO1();
    // ���������s���܂��B
    totalVo.initQuery(orderHeaderId);

  } // doSearchLine

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̐V�K���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventInsLine(
    String exeType,
    OARow prow
    )
  {
    // �N���^�C�v���u11�F�ɓ����p�v�ȊO�̏ꍇ
    if (!XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // ���ڐ���
      prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // �P����

    }
  } // handleEventInsHdr

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̍X�V���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param prow    - PVO�s�N���X
   * @param hdrRow  - �w�b�_VO�s�N���X
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void handleEventUpdLine(
    String exeType,
    OARow prow,
    OARow hdrRow
    ) throws OAException
  {
    // ������
    handleEventAllOnLine(prow);
    // �X�e�[�^�X���擾
    String transStatus = (String)hdrRow.getAttribute("TransStatus");

    // �N���^�C�v���u11�F�ɓ����p�v�ȊO�̏ꍇ
    if (!XxpoConstants.EXE_TYPE_11.equals(exeType)) 
    {
      // ���ڐ���
      prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // �P����
    }

    // �X�e�[�^�X���u��̍ρv�̏ꍇ 
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // ����No���擾
      String poNo = (String)hdrRow.getAttribute("PoNo");
      // �N���^�C�v���u11�F�ɓ����p�v�ȊO�̏ꍇ
      if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
      {
        // �����L�̏ꍇ
        if (!XxcmnUtility.isBlankOrNull(poNo)) 
        {
          // �{�^������
          prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // �s�}���{�^��
        }

      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // �Q�Ƃ̂�
        handleEventAllOffLine(prow);

      // �N���^�C�v���u15�F���ރ��[�J�[�p�v�̏ꍇ
      } else if (XxpoConstants.EXE_TYPE_15.equals(exeType)) 
      {
        // �����L�̏ꍇ
        if (!XxcmnUtility.isBlankOrNull(poNo)) 
        {
          // �{�^������
          prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // �s�}���{�^��
        }
      }

    // �X�e�[�^�X���u�o�׎��ьv��ρv�̏ꍇ 
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // �Q�Ƃ̂�
        handleEventAllOffLine(prow);

      } else
      {
        // ���z�m����擾
        String fixClass  = (String)hdrRow.getAttribute("FixClass");  

        // ���z�m��ς̏ꍇ
        if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
        {
          // �N���^�C�v���u11�F�ɓ����p�v�ȊO�̏ꍇ
          if (XxpoConstants.EXE_TYPE_11.equals(exeType)) 
          {
            // �{�^������
            prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // �s�}���{�^��

          } else 
          {
            // �Q�Ƃ̂�
            handleEventAllOffLine(prow);
          }
        }
      }
    }
  } // handleEventUpdLine

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOnLine(OARow prow)
  {
    prow.setAttribute("UnitPriceColRender" , Boolean.TRUE);  // �P����
    prow.setAttribute("ApplyBtnReject"     , Boolean.FALSE); // �K�p�{�^��
    prow.setAttribute("AddRowBtnRender"    , Boolean.TRUE); // �s�}���{�^��

  } // handleEventAllOnLine

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̍��ڂ�S��TRUE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOffLine(OARow prow)
  {
    prow.setAttribute("UnitPriceColRender" , Boolean.FALSE); // �P����
    prow.setAttribute("ApplyBtnReject"     , Boolean.TRUE);  // �K�p�{�^��
    prow.setAttribute("AddRowBtnRender"    , Boolean.FALSE);  // �s�}���{�^��

  } // handleEventAllOnLine

  /***************************************************************************
   * �x���w�����׉�ʂ̓K�p�������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   * @return  HashMap - �߂�l�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    boolean exeFlag = false; // ���s�t���O

    // �`�F�b�N����
    chkOrderLine(exeType);

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // �V�K�t���O
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // �˗�No
    String tokenName = null;

    // �V�K�t���O���uN�F�X�V�v�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // �r���`�F�b�N
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;

    // �V�K�̏ꍇ
    } else
    {
      // �˗�No���擾
      reqNo = XxcmnUtility.getSeqNo(getOADBTransaction(), XxpoConstants.TOKEN_NAME_REQUEST_NO);
      // �󒍃w�b�_�A�h�I��ID���擾
      Number orderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());

      // row�ɐݒ�
      hdrRow.setAttribute("RequestNo", reqNo);
      hdrRow.setAttribute("OrderHeaderId", orderHeaderId);

      tokenName = XxpoConstants.TOKEN_NAME_INS;

    }

    // �˗����ˎw�����R�s�[����
    doCopyReqQty();

    // �ǉ��E�X�V����
    if (doExecute(newFlag, hdrRow, exeType)) 
    {
      // �R�~�b�g����
      XxpoUtility.commit(getOADBTransaction());

    } else
    {
      // ���[���o�b�N����
      XxpoUtility.rollBack(getOADBTransaction());
      tokenName = null;

    }

    HashMap retParams = new HashMap();
    retParams.put("tokenName", tokenName); // �g�[�N������
    retParams.put("reqNo",     reqNo);     // �˗�No

    return retParams;

  } // doApply

  /***************************************************************************
   * �}���E�X�V�������s�����\�b�h�ł��B
   * @param newFlag  - �V�K�t���O Y:�V�K�AN:�X�V
   * @param hdrRow   - �w�b�_�s�I�u�W�F�N�g
   * @param exeType  - �N���^�C�v
   * @return boolean - �������s�t���O true:���s
   *                                false:�����s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean doExecute(
    String newFlag,
    OARow  hdrRow,
    String exeType
    ) throws OAException
  {
    boolean sumQtyFlag            = false; // ���v���ʕύX�t���O
    boolean lineExeFlag           = false; // ���׎��s�t���O
    boolean hdrExeFlag            = false; // �w�b�_���s�t���O
    boolean cancelCarriersFlag    = false; // �z�ԉ����t���O
    boolean changeHdrFlag         = false; // �d�v�w�b�_���ڕύX�t���O
    boolean changeLineFlag        = false; // �d�v���׍��ڕύX�t���O
    boolean setMaxShipToFlag      = false; // �ő�z���敪�ݒ�t���O
    boolean freightOnFlag         = false; // �^���敪�u�ΏۊO�ˑΏہv�ݒ�t���O
    boolean freightOffFlag        = false; // �^���敪�u�ΏہˑΏۊO�v�ݒ�t���O
// 2008-10-27 D.Nihei ADD START
    boolean updNotifStatusFlag    = false; // �ʒm�X�e�[�^�X�X�V�t���O
// 2008-10-27 D.Nihei ADD END

    /****************************
     * �w�b�_�e����擾
     ****************************/
    String rcvType            = (String)hdrRow.getAttribute("RcvType");             // ��̃^�C�v
    String transStatus        = (String)hdrRow.getAttribute("TransStatus");         // �X�e�[�^�X
    String freightClass       = (String)hdrRow.getAttribute("FreightChargeClass");  // �^���敪
    String dbFreightClass     = (String)hdrRow.getAttribute("DbFreightChargeClass");// �^���敪(DB)
    String vendorCode         = (String)hdrRow.getAttribute("VendorCode");          // �����
    String weightCapaClass    = (String)hdrRow.getAttribute("WeightCapacityClass"); // �d�ʗe�ϋ敪
    String shipToCode         = (String)hdrRow.getAttribute("ShipToCode");          // �z����
    String shipWhseCode       = (String)hdrRow.getAttribute("ShipWhseCode");        // �o�ɑq��
    Date shippedDate          = (Date)hdrRow.getAttribute("ShippedDate");           // �o�ɓ�
    String reqNo              = (String)hdrRow.getAttribute("RequestNo");           // �˗�No
    Object freightCarrierCode = hdrRow.getAttribute("FreightCarrierCode");          // �^���Ǝ�
    Date arrivalDate          = (Date)hdrRow.getAttribute("ArrivalDate");           // ���ɓ�

    /****************************
     * �^���敪����
     ****************************/
    // �V�K�̏ꍇ
    if (XxcmnUtility.isBlankOrNull(dbFreightClass)) 
    {
      // �^���敪(DB)�Ɂu�ΏۊO�v��ݒ�
      dbFreightClass = XxcmnConstants.STRING_ZERO;  
    }
    // �u�ΏۊO�v�ˁu�Ώہv�ɂȂ����ꍇ
    if (XxcmnUtility.chkCompareNumeric(1, freightClass, dbFreightClass)) 
    {
      freightOnFlag = true;

    // �u�Ώہv�ˁu�ΏۊO�v�ɂȂ����ꍇ
    } else if (XxcmnUtility.chkCompareNumeric(1, dbFreightClass, freightClass))
    {
      freightOffFlag = true;

    }
    /****************************
     * �d�v�w�b�_���ڕύX����(�����A�z����A�o�ɑq�ɁA�o�ɓ��A���ɓ��A�^���Ǝ�)
     ****************************/
    if (!XxcmnUtility.isEquals(vendorCode,         hdrRow.getAttribute("DbVendorCode"))
     || !XxcmnUtility.isEquals(shipToCode,         hdrRow.getAttribute("DbShipToCode"))
     || !XxcmnUtility.isEquals(shipWhseCode,       hdrRow.getAttribute("DbShipWhseCode"))
     || !XxcmnUtility.isEquals(shippedDate,        hdrRow.getAttribute("DbShippedDate"))
     || !XxcmnUtility.isEquals(arrivalDate,        hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(freightCarrierCode, hdrRow.getAttribute("DbFreightCarrierCode"))) 
    {
      changeHdrFlag = true;

    }

    // �x���w���쐬����VO
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();

    /****************************
     * ���׍X�V�s�擾
     ****************************/
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if (updRows != null || updRows.length > 0) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        updRow = (OARow)updRows[i];

        /******************
         * ���׊e����擾
         ******************/
        Object itemId         = updRow.getAttribute("ItemId");                // �i��ID
        Object dbItemId       = updRow.getAttribute("DbItemId");              // �i��ID(DB)
        Object futaiCode      = updRow.getAttribute("FutaiCode");             // �t�уR�[�h
        Object dbFutaiCode    = updRow.getAttribute("DbFutaiCode");           // �t�уR�[�h(DB)
        Object reqQuantity    = updRow.getAttribute("ReqQuantity");           // �˗���
        Object dbReqQuantity  = updRow.getAttribute("DbReqQuantity");         // �˗���(DB)
        Object unitPriceNum   = updRow.getAttribute("UnitPriceNum");          // �P��
        Object dbUnitPriceNum = updRow.getAttribute("DbUnitPriceNum");        // �P��(DB)
        Object description    = updRow.getAttribute("LineDescription");       // ���l
        Object dbDescription  = updRow.getAttribute("DbLineDescription");     // ���l(DB)
        String instQuantity   = (String)updRow.getAttribute("InstQuantity");  // �w����
        String dbInstQuantity = (String)updRow.getAttribute("DbInstQuantity");// �w����(DB)

        // �d�v���׍��ڕύX����(�i��ID�A�˗���)
        if (!XxcmnUtility.isEquals(itemId,      dbItemId)
         || !XxcmnUtility.isEquals(reqQuantity, dbReqQuantity)) 
        {
          // �d�v���׍��ڕύX�t���O��true�ɕύX
          changeLineFlag = true;  

        }
        // �i��ID�A�˗����A�t�уR�[�h�A�P���A���l���ύX���ꂽ�ꍇ
        if ( changeLineFlag
         || !XxcmnUtility.isEquals(futaiCode,    dbFutaiCode)
         || !XxcmnUtility.isEquals(unitPriceNum, dbUnitPriceNum)
         || !XxcmnUtility.isEquals(description,  dbDescription)) 
        {
          // �z�ԉ����v�۔���(�i��ID)
          if (!XxcmnUtility.isEquals(itemId, dbItemId))
          {
            // �z�ԉ����t���O��true�ɂ���
            cancelCarriersFlag = true;  

          }
          // �X�V����
          updateOrderLine(updRow);

          // ���׎��s�t���O��true�ɕύX
          lineExeFlag = true;

        }
        // �w�������ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(XxcmnUtility.commaRemoval(instQuantity), 
                                   XxcmnUtility.commaRemoval(dbInstQuantity))) 
        {
          // ���v���ʕύX�t���O��true�ɕύX
          sumQtyFlag = true;

        }
      }
    }

    /****************************
     * ���גǉ��s�擾
     ****************************/
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        insRow = (OARow)insRows[i];

        /******************
         * ���׊e����擾
         ******************/
        Object itemNo      = insRow.getAttribute("ItemNo");          // �i��ID
        Object futaiCode   = insRow.getAttribute("FutaiCode");       // �t��
        Object reqQuantity = insRow.getAttribute("ReqQuantity");     // �˗���
        Object description = insRow.getAttribute("LineDescription"); // ���l
        
        // �����ꂩ�̍��ڂ����͂���Ă���ꍇ
        if (!XxcmnUtility.isBlankOrNull(itemNo)
         || !XxcmnUtility.isBlankOrNull(reqQuantity)
         || !XxcmnUtility.isBlankOrNull(description)) 
        {
          // �z�ԉ����v�۔���(�z�ԍς̏ꍇ)
          if (XxpoConstants.RCV_TYPE_3.equals(rcvType)
           || XxpoConstants.RCV_TYPE_4.equals(rcvType)) 
          {
            // �z�ԉ����t���O��true�ɂ���
            cancelCarriersFlag = true;  

          }
// 2008-10-27 D.Nihei ADD START
          // �u��̍ρv���ɖ��ׂ��ǉ����ꂽ�ꍇ
          if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)) 
          {
            // �ʒm�X�e�[�^�X�X�V�t���O��true�ɂ���
            updNotifStatusFlag = true; 
          }
// 2008-10-27 D.Nihei ADD RND
          // �}������
          insertOrderLine(hdrRow, insRow);

          // ���׎��s�t���O��true�ɕύX
          lineExeFlag = true;

          // ���v���ʕύX�t���O��true�ɕύX
          sumQtyFlag = true;

          // �X�e�[�^�X���u�o�׎��ьv��ρv�̏ꍇ�́A�t���O�𗧂ĂȂ��B
          if (!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
          {
            // �d�v���׍��ڕύX�t���O��false�ɕύX
            changeLineFlag = false;  

          }
        // ����ȊO
        } else
        {
          // �s�v�s�폜
          insRow.remove();

        }
      }
    }
    // ���׌�����0���̏ꍇ
    if (vo.getFetchedRowCount() == 0) 
    {
      // �s�ǉ�  
      addRow(exeType);
      // �G���[����
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10146);
      
    }
    
    /****************************
     * �z�Ԋ֘A��񓱏o����
     ****************************/
    if (changeHdrFlag || changeLineFlag || freightOnFlag) 
    {
      /******************
       * �z�Ԋ֘A���ݒ�
       ******************/
      setCarriersData(hdrRow);

    }

    // �^���敪���u�Ώہv�̏ꍇ
    if (XxcmnUtility.isEquals(freightClass, XxcmnConstants.OBJECT_ON)) 
    {
      /******************
       * �ő�z���敪�擾
       ******************/
      HashMap paramsRet = XxpoUtility.getMaxShipMethod(
                            getOADBTransaction(),
                            "4",  // �q��
                            shipWhseCode,
                            "11", // �x����
                            shipToCode,
                            weightCapaClass,
                            null,
                            shippedDate); 
      // �ő�z���敪���Z�b�g����
      String maxShipToCode = (String)paramsRet.get("maxShipMethods");
      // �ő�z���敪���擾�ł��Ȃ������ꍇ
      if (XxcmnUtility.isBlankOrNull(maxShipToCode)) 
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        // �G���[���b�Z�[�W�o��
        MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                   "�ő�z���敪�̎擾") };
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN05002,
                              tokens);
    
      // �w�b�_�̏d�v���ڂ��ύX���ꂽ�A�܂��͔z���敪���ݒ肳��Ă��Ȃ��ꍇ�ɂ̂ݐݒ�
      } else if (changeHdrFlag || XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("ShippingMethodCode"))) 
      {
        /******************
         * �e���ڂ��Z�b�g
         ******************/
        hdrRow.setAttribute("ShippingMethodCode", paramsRet.get("maxShipMethods"));  // �z���敪
        hdrRow.setAttribute("BasedWeight",        paramsRet.get("deadweight"));      // ��{�d��
        hdrRow.setAttribute("BasedCapacity",      paramsRet.get("loadingCapacity")); // ��{�e��
        setMaxShipToFlag = true;

      }
      // �ύڌ����`�F�b�N(�ύڌ����Z�o)���{����
      if (freightOnFlag || changeHdrFlag || changeLineFlag)
      {
        // �d�ʗe�ϋ敪�ɂ���ēn���p�����[�^��������
// 2008-07-29 D.Nihei DEL START
//        String sumWeight   = null;
//        String sumCapacity = null;
//        // �d�ʗe�ϋ敪���A�u�d�ʁv�̏ꍇ
//        if (XxpoConstants.WGHT_CAPA_CLASS_WEIGHT.equals(weightCapaClass)) 
//        {
//          sumWeight   = (String)hdrRow.getAttribute("SumWeight");
//        // ����ȊO
//        } else 
//        {
//          sumCapacity = (String)hdrRow.getAttribute("SumCapacity");
//        }
// 2008-07-29 D.Nihei DEL END
        /******************
         * �d�ʐύڌ����`�F�b�N(�ύڌ����Z�o)
         ******************/
        HashMap params1 = XxpoUtility.calcLoadEfficiency(
                           getOADBTransaction(),
// 2008-07-29 D.Nihei MOD START
//                           sumWeight,
//                           sumCapacity,
                           (String)hdrRow.getAttribute("SumWeight"),
                           null,
// 2008-07-29 D.Nihei MOD END
                           "4",  // �q��
                           shipWhseCode,
                           "11", // �x����
                           shipToCode,
                           maxShipToCode,
                           shippedDate,
                           true);
        /******************
         * �e���ڂ��Z�b�g
         ******************/
        hdrRow.setAttribute("EfficiencyWeight",   params1.get("loadEfficiencyWeight"));   // �d�ʐύڌ���
// 2008-07-29 D.Nihei ADD START
        /******************
         * �e�ϐύڌ����`�F�b�N(�ύڌ����Z�o)
         ******************/
        HashMap params2 = XxpoUtility.calcLoadEfficiency(
                           getOADBTransaction(),
                           null,
                           (String)hdrRow.getAttribute("SumCapacity"),
                           "4",  // �q��
                           shipWhseCode,
                           "11", // �x����
                           shipToCode,
                           maxShipToCode,
                           shippedDate,
                           true);
        /******************
         * �e���ڂ��Z�b�g
         ******************/
// 2008-07-29 D.Nihei ADD END
        hdrRow.setAttribute("EfficiencyCapacity", params2.get("loadEfficiencyCapacity")); // �e�ϐύڌ���
      }
    }
    /****************************
     * �w�b�_�V�K�ǉ��E�X�V����
     ****************************/
    // �w�b�_�V�K�ǉ��̏ꍇ
    if (XxcmnConstants.STRING_Y.equals(newFlag)) 
    {
      /******************
       * �}������
       ******************/
      insertOrderHdr(hdrRow);
      // �w�b�_���s�t���O��true�ɕύX
      hdrExeFlag = true;
      
    // �w�b�_�X�V�̏ꍇ
    } else
    {
      /******************
       * �w�b�_�e����擾
       ******************/
      Object orderTypeId  = hdrRow.getAttribute("OrderTypeId");        // �����敪
      Object reqDeptCode  = hdrRow.getAttribute("ReqDeptCode");        // �˗�����
      Object instDeptCode = hdrRow.getAttribute("InstDeptCode");       // �w������
    
      // �ȉ����ύX���ꂽ�ꍇ
      // �E�����敪 �E�d�ʗe�ϋ敪 �E�˗�����    �E�w������ �E�����
      // �E�z����   �E�o�ɑq��    �E�^���Ǝ�    �E�o�ɓ�   �E���ɓ�
      // �E���׎���(From)        �E���׎���(To)�E�z���敪 �E�^���敪
      // �E����敪 �E������      �E�����i��    �E�����ԍ� �E�E�v
      // �E�w����� �E���z�m��    �E���v���ʕύX�t���OsumQtyFlag
      if ( changeHdrFlag
       || !XxcmnUtility.isEquals(orderTypeId,        hdrRow.getAttribute("DbOrderTypeId"))
       || !XxcmnUtility.isEquals(weightCapaClass,    hdrRow.getAttribute("DbWeightCapacityClass"))
       || !XxcmnUtility.isEquals(reqDeptCode,        hdrRow.getAttribute("DbReqDeptCode"))
       || !XxcmnUtility.isEquals(instDeptCode,       hdrRow.getAttribute("DbInstDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingMethodCode"),   hdrRow.getAttribute("DbShippingMethodCode"))
       || !XxcmnUtility.isEquals(freightClass,       dbFreightClass)
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("TakebackClass"),        hdrRow.getAttribute("DbTakebackClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedProdDate"),   hdrRow.getAttribute("DbDesignatedProdDate"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedItemCode"),   hdrRow.getAttribute("DbDesignatedItemCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedBranchNo"),   hdrRow.getAttribute("DbDesignatedBranchNo"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),             hdrRow.getAttribute("DbRcvClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))
       || sumQtyFlag) 
      {
        /******************
         * �z�Ԋ֘A���N���A����
         ******************/
        if (freightOffFlag) 
        {
          // �z�Ԋ֘A�����N���A
          hdrRow.setAttribute("ShippingMethodCode", null); // �z���敪
          hdrRow.setAttribute("EfficiencyWeight",   null); // �d�ʐύڌ���
          hdrRow.setAttribute("EfficiencyCapacity", null); // �e�ϐύڌ���
          hdrRow.setAttribute("BasedWeight",        null); // ��{�d��
          hdrRow.setAttribute("BasedCapacity",      null); // ��{�e��

        }
        /******************
         * �X�V����
         ******************/
        updateOrderHdr(hdrRow);
        // �w�b�_���s�t���O��true�ɕύX
        hdrExeFlag = true;

      }
    }
    /******************
     * �z�ԉ�������
     ******************/
    // ��̃^�C�v��Null�ȊO�A�u�^���敪�v��ΏہˑΏۊO�ɂ����A
    // �܂��́A�w�b�_�̏d�v���ڂ��ύX���ꂽ�ꍇ
    if (!XxcmnUtility.isBlankOrNull(rcvType) 
     && (freightOffFlag || changeHdrFlag)) 
    {
      // �z�ԉ����t���O��true�ɂ���
      cancelCarriersFlag = true;

    // �z��No��Null�Ńw�b�_�A���ׂ̏d�v���ڂ��ύX���ꂽ�ꍇ
    } else if (XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("ShipToNo"))
// 2008-10-27 D.Nihei MOD START
//            && (hdrExeFlag || lineExeFlag))
            && (changeHdrFlag || changeLineFlag))
// 2008-10-27 D.Nihei MOD END
    {
      // �z�ԉ����t���O��true�ɂ���
      cancelCarriersFlag = true;

    }
// 2008-10-27 D.Nihei ADD START
    // �^���敪���ΏۊO�ˑΏ�,�A���׎���From�A���׎���TO�A�E�v���ύX���ꂽ�ꍇ
    if (freightOnFlag
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))) 
    {
      // �ʒm�X�e�[�^�X�X�V�t���O��true�ɂ���
      updNotifStatusFlag = true; 
    }
// 2008-10-27 D.Nihei ADD END

    /******************
     * �z�ԉ�������
     ******************/
    if (cancelCarriersFlag) 
    {
      String retCode = XxwshUtility.cancelCareersSchedile(
                         getOADBTransaction(),
                         XxcmnConstants.BIZ_TYPE_PROV,
                         reqNo);
      // �p�����[�^�`�F�b�N�G���[�̏ꍇ
      if (XxcmnConstants.API_PARAM_ERROR.equals(retCode)) 
      {
        // �\�����ʃG���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123
                              );
            
      // �z�ԏ������s�̏ꍇ
      } else if (XxcmnConstants.API_CANCEL_CARRER_ERROR.equals(retCode)) 
      {
        XxcmnUtility.putErrorMessage(XxpoConstants.TOKEN_NAME_CAN_CAREERS);

      }
// 2008-10-27 D.Nihei ADD START
    } else if (updNotifStatusFlag)
    {
      // �ʒm�X�e�[�^�X�X�V�֐������s����B
      XxwshUtility.updateNotifStatus(
        getOADBTransaction(),
        XxcmnConstants.BIZ_TYPE_PROV,
        reqNo);
// 2008-10-27 D.Nihei ADD END
    }

    return (hdrExeFlag || lineExeFlag);

  } // doExecute

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void insertOrderHdr(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "insertOrderHdr";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_headers_all(");
    sb.append("    order_header_id            "); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,order_type_id              "); // �󒍃^�C�vID
    sb.append("   ,organization_id            "); // �g�DID
    sb.append("   ,latest_external_flag       "); // �ŐV�t���O
    sb.append("   ,ordered_date               "); // �󒍓�
    sb.append("   ,customer_id                "); // �ڋqID
    sb.append("   ,customer_code              "); // �ڋq
    sb.append("   ,shipping_instructions      "); // �o�׎w��
    sb.append("   ,career_id                  "); // �^���Ǝ�ID
    sb.append("   ,freight_carrier_code       "); // �^���Ǝ�
    sb.append("   ,shipping_method_code       "); // �z���敪
    sb.append("   ,request_no                 "); // �˗�No
    sb.append("   ,base_request_no            "); // ���˗�No
    sb.append("   ,req_status                 "); // �X�e�[�^�X
    sb.append("   ,schedule_ship_date         "); // �o�ח\���
    sb.append("   ,schedule_arrival_date      "); // ���ח\���
    sb.append("   ,freight_charge_class       "); // �^���敪
    sb.append("   ,shikyu_inst_rcv_class      "); // �x���w����̋敪
    sb.append("   ,amount_fix_class           "); // �L�����z�m��敪
    sb.append("   ,takeback_class             "); // ����敪
    sb.append("   ,deliver_from_id            "); // �o�׌�ID
    sb.append("   ,deliver_from               "); // �o�׌��ۊǏꏊ
    sb.append("   ,prod_class                 "); // ���i�敪
    sb.append("   ,arrival_time_from          "); // ���׎���FROM
    sb.append("   ,arrival_time_to            "); // ���׎���TO
    sb.append("   ,designated_item_id         "); // �����i��ID
    sb.append("   ,designated_item_code       "); // �����i��
    sb.append("   ,designated_production_date "); // ������
    sb.append("   ,designated_branch_no       "); // �����}��
    sb.append("   ,sum_quantity               "); // ���v����
    sb.append("   ,small_quantity             "); // ������
    sb.append("   ,label_quantity             "); // ���x������
    sb.append("   ,loading_efficiency_weight  "); // �d�ʐύڌ���
    sb.append("   ,loading_efficiency_capacity"); // �e�ϐύڌ���
    sb.append("   ,based_weight               "); // ��{�d��
    sb.append("   ,based_capacity             "); // ��{�e��
    sb.append("   ,sum_weight                 "); // �ύڏd�ʍ��v
    sb.append("   ,sum_capacity               "); // �ύڗe�ύ��v
    sb.append("   ,weight_capacity_class      "); // �d�ʗe�ϋ敪
    sb.append("   ,actual_confirm_class       "); // ���ьv��ϋ敪
    sb.append("   ,notif_status               "); // �ʒm�X�e�[�^�X
    sb.append("   ,new_modify_flg             "); // �V�K�C���t���O
    sb.append("   ,performance_management_dept"); // ���ъǗ�����
    sb.append("   ,instruction_dept           "); // �w������
    sb.append("   ,vendor_id                  "); // �����ID
    sb.append("   ,vendor_code                "); // �����
    sb.append("   ,vendor_site_id             "); // �����T�C�gID
    sb.append("   ,vendor_site_code           "); // �����T�C�g
    sb.append("   ,created_by                 "); // �쐬��
    sb.append("   ,creation_date              "); // �쐬��
    sb.append("   ,last_updated_by            "); // �ŏI�X�V��
    sb.append("   ,last_update_date           "); // �ŏI�X�V��
    sb.append("   ,last_update_login)         "); // �ŏI�X�V���O�C��
    sb.append("  VALUES( ");
    sb.append("    :1 ");
    sb.append("   ,:2 ");
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') ");
    sb.append("   ,'Y' ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,:3 ");
    sb.append("   ,:4 ");
    sb.append("   ,:5 ");
    sb.append("   ,:6 ");
    sb.append("   ,:7 ");
    sb.append("   ,:8 ");
    sb.append("   ,:9 ");
    sb.append("   ,:10 ");
    sb.append("   ,'05' ");
    sb.append("   ,:11 ");
    sb.append("   ,:12 ");
    sb.append("   ,:13 ");
    sb.append("   ,:14 ");
    sb.append("   ,:15 ");
    sb.append("   ,:16 ");
    sb.append("   ,:17 ");
    sb.append("   ,:18 ");
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') ");
    sb.append("   ,:19 ");
    sb.append("   ,:20 ");
    sb.append("   ,:21 ");
    sb.append("   ,:22 ");
    sb.append("   ,:23 ");
    sb.append("   ,:24 ");
    sb.append("   ,TO_NUMBER(:25) ");
    sb.append("   ,TO_NUMBER(:26) ");
    sb.append("   ,TO_NUMBER(:27) ");
    sb.append("   ,TO_NUMBER(:28) ");
    sb.append("   ,TO_NUMBER(:29) ");
    sb.append("   ,TO_NUMBER(:30) ");
    sb.append("   ,TO_NUMBER(:31) ");
    sb.append("   ,TO_NUMBER(:32) ");
    sb.append("   ,TO_NUMBER(:33) ");
    sb.append("   ,:34 ");
    sb.append("   ,'N' ");
    sb.append("   ,'10' ");
    sb.append("   ,'N' ");
    sb.append("   ,:35 ");
    sb.append("   ,:36 ");
    sb.append("   ,:37 ");
    sb.append("   ,:38 ");
    sb.append("   ,:39 ");
    sb.append("   ,:40 ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.LOGIN_ID); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // �󒍃w�b�_�A�h�I��ID
      Number orderTypeId         = (Number)hdrRow.getAttribute("OrderTypeId");           // �����敪
      Number customerId          = (Number)hdrRow.getAttribute("CustomerId");            // �ڋqID
      String customerCode        = (String)hdrRow.getAttribute("CustomerCode");          // �ڋq
      String instructions        = (String)hdrRow.getAttribute("ShippingInstructions");  // �E�v
      Number freightCarrierId    = (Number)hdrRow.getAttribute("FreightCarrierId");      // �^���Ǝ�ID
      String freightCarrierCode  = (String)hdrRow.getAttribute("FreightCarrierCode");    // �^���Ǝ�
      String shippingMethodCode  = (String)hdrRow.getAttribute("ShippingMethodCode");    // �z���敪
      String requestNo           = (String)hdrRow.getAttribute("RequestNo");             // �˗�No
      String baseRequestNo       = (String)hdrRow.getAttribute("BaseRequestNo");         // ���˗�No
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // �o�ɗ\���
      Date   arrivalDate         = (Date)hdrRow.getAttribute("ArrivalDate");             // ���ɗ\���
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // �^���敪
      String rcvClass            = (String)hdrRow.getAttribute("RcvClass");              // �w�����
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // ���z�m��
      String takebackClass       = (String)hdrRow.getAttribute("TakebackClass");         // ����敪
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // �o�ɑq��ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // �o�ɑq��
      String arrivalTimeFrom     = (String)hdrRow.getAttribute("ArrivalTimeFrom");       // ���׎���From
      String arrivalTimeTo       = (String)hdrRow.getAttribute("ArrivalTimeTo");         // ���׎���To
      Number designatedItemId    = (Number)hdrRow.getAttribute("DesignatedItemId");      // �����i��ID(INV)
      String designatedItemCode  = (String)hdrRow.getAttribute("DesignatedItemCode");    // �����i��No
      Date   designatedProdDate  = (Date)hdrRow.getAttribute("DesignatedProdDate");      // ������
      String designatedBranchNo  = (String)hdrRow.getAttribute("DesignatedBranchNo");    // �����ԍ�
      String sumQuantity         = (String)hdrRow.getAttribute("SumQuantity");           // ���v����
      Number smallQuantity       = (Number)hdrRow.getAttribute("SmallQuantity");         // ������
      Number labelQuantity       = (Number)hdrRow.getAttribute("LabelQuantity");         // ���x������
      String efficiencyWeight    = (String)hdrRow.getAttribute("EfficiencyWeight");      // �d�ʐύڌ���
      String efficiencyCapacity  = (String)hdrRow.getAttribute("EfficiencyCapacity");    // �e�ϐύڌ���
      String basedWeight         = (String)hdrRow.getAttribute("BasedWeight");           // ��{�d��
      String basedCapacity       = (String)hdrRow.getAttribute("BasedCapacity");         // ��{�e��
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // �ύڏd�ʍ��v
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // �ύڗe�ύ��v
      String weightCapacityClass = (String)hdrRow.getAttribute("WeightCapacityClass");   // �d�ʗe�ϋ敪
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // �˗�����
      String instDeptCode        = (String)hdrRow.getAttribute("InstDeptCode");          // �w������
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // �����ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // �����
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // �z����ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // �z����

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // �����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // �ڋqID
      cstmt.setString(i++, customerCode);                         // �ڋq
      cstmt.setString(i++, instructions);                         // �E�v
      if (XxcmnUtility.isBlankOrNull(freightCarrierId)) 
      {
        cstmt.setNull(i++, Types.INTEGER); // �^���Ǝ�ID
      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(freightCarrierId)); // �^���Ǝ�ID
        
      }
      cstmt.setString(i++, freightCarrierCode);                   // �^���Ǝ�
      cstmt.setString(i++, shippingMethodCode);                   // �z���敪
      cstmt.setString(i++, requestNo);                            // �˗�No
      cstmt.setString(i++, baseRequestNo);                        // ���˗�No
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // �o�ɓ�
      cstmt.setDate(i++, XxcmnUtility.dateValue(arrivalDate));    // ���ɓ�
      cstmt.setString(i++, freightChargeClass);                   // �^���敪
      cstmt.setString(i++, rcvClass);                             // �w�����
      cstmt.setString(i++, fixClass);                             // ���z�m��
      cstmt.setString(i++, takebackClass);                        // ����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // �o�ɑq��ID
      cstmt.setString(i++, shipWhseCode);                         // �o�ɑq��
      cstmt.setString(i++, arrivalTimeFrom);                      // ���׎���From
      cstmt.setString(i++, arrivalTimeTo);                        // ���׎���To
      if (XxcmnUtility.isBlankOrNull(designatedItemId)) 
      {
        cstmt.setNull(i++, Types.NUMERIC); // �����i��ID(INV)

      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(designatedItemId)); // �����i��ID(INV)

      }
      cstmt.setString(i++, designatedItemCode);                   // �����i��No
      cstmt.setDate(i++, XxcmnUtility.dateValue(designatedProdDate)); // ������
      cstmt.setString(i++, designatedBranchNo);                       // �����ԍ�
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumQuantity));   // ���v����
      cstmt.setString(i++, XxcmnUtility.stringValue(smallQuantity));  // ������
      cstmt.setString(i++, XxcmnUtility.stringValue(labelQuantity));  // ���x������
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyWeight));   // �d�ʐύڌ���
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyCapacity)); // �e�ϐύڌ���
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedWeight));   // ��{�d��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedCapacity)); // ��{�e��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));     // �ύڏd�ʍ��v
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));   // �ύڗe�ύ��v
      cstmt.setString(i++, weightCapacityClass);                  // �d�ʗe�ϋ敪
      cstmt.setString(i++, reqDeptCode);                          // �˗�����
      cstmt.setString(i++, instDeptCode);                         // �w������
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // �����ID
      cstmt.setString(i++, vendorCode);                           // �����
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // �z����ID
      cstmt.setString(i++, shipToCode);                           // �z����
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderHdr 

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void updateOrderHdr(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "updateOrderHdr";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.order_type_id               = :1 " ); // �󒍃^�C�vID
    sb.append("       ,xoha.customer_id                 = :2 " ); // �ڋqID
    sb.append("       ,xoha.customer_code               = :3 " ); // �ڋq
    sb.append("       ,xoha.shipping_instructions       = :4 " ); // �o�׎w��
    sb.append("       ,xoha.career_id                   = :5 " ); // �^���Ǝ�ID
    sb.append("       ,xoha.freight_carrier_code        = :6 " ); // �^���Ǝ�
    sb.append("       ,xoha.shipping_method_code        = :7 " ); // �z���敪
    sb.append("       ,xoha.schedule_ship_date          = NVL(:8, xoha.schedule_ship_date)   "); // �o�ח\���
    sb.append("       ,xoha.schedule_arrival_date       = NVL(:9, xoha.schedule_arrival_date)"); // ���ח\���
    sb.append("       ,xoha.freight_charge_class        = :10 " ); // �^���敪
    sb.append("       ,xoha.amount_fix_class            = :11 " ); // �L�����z�m��敪
    sb.append("       ,xoha.takeback_class              = :12 " ); // ����敪
    sb.append("       ,xoha.deliver_from_id             = :13 " ); // �o�׌�ID
    sb.append("       ,xoha.deliver_from                = :14 " ); // �o�׌��ۊǏꏊ
    sb.append("       ,xoha.arrival_time_from           = :15 " ); // ���׎���FROM
    sb.append("       ,xoha.arrival_time_to             = :16 " ); // ���׎���TO
    sb.append("       ,xoha.designated_item_id          = :17 " ); // �����i��ID
    sb.append("       ,xoha.designated_item_code        = :18 " ); // �����i��
    sb.append("       ,xoha.designated_production_date  = :19 " ); // ������
    sb.append("       ,xoha.designated_branch_no        = :20 " ); // �����}��
    sb.append("       ,xoha.sum_quantity                = TO_NUMBER(:21) " ); // ���v����
    sb.append("       ,xoha.small_quantity              = TO_NUMBER(:22) " ); // ������
    sb.append("       ,xoha.label_quantity              = TO_NUMBER(:23) " ); // ���x������
    sb.append("       ,xoha.loading_efficiency_weight   = TO_NUMBER(:24) " ); // �d�ʐύڌ���
    sb.append("       ,xoha.loading_efficiency_capacity = TO_NUMBER(:25) " ); // �e�ϐύڌ���
    sb.append("       ,xoha.based_weight                = TO_NUMBER(:26) " ); // ��{�d��
    sb.append("       ,xoha.based_capacity              = TO_NUMBER(:27) " ); // ��{�e��
    sb.append("       ,xoha.sum_weight                  = TO_NUMBER(:28) " ); // �ύڏd�ʍ��v
    sb.append("       ,xoha.sum_capacity                = TO_NUMBER(:29) " ); // �ύڗe�ύ��v
    sb.append("       ,xoha.performance_management_dept = :30 " ); // ���ъǗ�����
    sb.append("       ,xoha.instruction_dept            = :31 " ); // �w������
    sb.append("       ,xoha.vendor_id                   = :32 " ); // �����ID
    sb.append("       ,xoha.vendor_code                 = :33 " ); // �����
    sb.append("       ,xoha.vendor_site_id              = :34 " ); // �����T�C�gID
    sb.append("       ,xoha.vendor_site_code            = :35 " ); // �����T�C�g
    sb.append("       ,xoha.last_updated_by             = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("       ,xoha.last_update_date            = SYSDATE "             ); // �ŏI�X�V��
    sb.append("       ,xoha.last_update_login           = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id = :36; "); // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number orderTypeId         = (Number)hdrRow.getAttribute("OrderTypeId");           // �����敪
      Number customerId          = (Number)hdrRow.getAttribute("CustomerId");            // �ڋqID
      String customerCode        = (String)hdrRow.getAttribute("CustomerCode");          // �ڋq
      String instructions        = (String)hdrRow.getAttribute("ShippingInstructions");  // �E�v
      Number freightCarrierId    = (Number)hdrRow.getAttribute("FreightCarrierId");      // �^���Ǝ�ID
      String freightCarrierCode  = (String)hdrRow.getAttribute("FreightCarrierCode");    // �^���Ǝ�
      String shippingMethodCode  = (String)hdrRow.getAttribute("ShippingMethodCode");    // �z���敪
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // �o�ɗ\���
      Date   arrivalDate         = (Date)hdrRow.getAttribute("ArrivalDate");             // ���ɗ\���
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // �^���敪
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // ���z�m��
      String takebackClass       = (String)hdrRow.getAttribute("TakebackClass");         // ����敪
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // �o�ɑq��ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // �o�ɑq��
      String arrivalTimeFrom     = (String)hdrRow.getAttribute("ArrivalTimeFrom");       // ���׎���From
      String arrivalTimeTo       = (String)hdrRow.getAttribute("ArrivalTimeTo");         // ���׎���To
      Number designatedItemId    = (Number)hdrRow.getAttribute("DesignatedItemId");      // �����i��ID(INV)
      String designatedItemCode  = (String)hdrRow.getAttribute("DesignatedItemCode");    // �����i��No
      Date   designatedProdDate  = (Date)hdrRow.getAttribute("DesignatedProdDate");      // ������
      String designatedBranchNo  = (String)hdrRow.getAttribute("DesignatedBranchNo");    // �����ԍ�
      String sumQuantity         = (String)hdrRow.getAttribute("SumQuantity");           // ���v����
      Number smallQuantity       = (Number)hdrRow.getAttribute("SmallQuantity");         // ������
      Number labelQuantity       = (Number)hdrRow.getAttribute("LabelQuantity");         // ���x������
      String efficiencyWeight    = (String)hdrRow.getAttribute("EfficiencyWeight");      // �d�ʐύڌ���
      String efficiencyCapacity  = (String)hdrRow.getAttribute("EfficiencyCapacity");    // �e�ϐύڌ���
      String basedWeight         = (String)hdrRow.getAttribute("BasedWeight");           // ��{�d��
      String basedCapacity       = (String)hdrRow.getAttribute("BasedCapacity");         // ��{�e��
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // �ύڏd�ʍ��v
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // �ύڗe�ύ��v
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // �˗�����
      String instDeptCode        = (String)hdrRow.getAttribute("InstDeptCode");          // �w������
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // �����ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // �����
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // �z����ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // �z����
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // �󒍃w�b�_�A�h�I��ID
      Number resultFreightCarrierId   = (Number)hdrRow.getAttribute("DbResultFreightCarrierId");   // �^���Ǝ�ID(����)
      String resultFreightCarrierCode = (String)hdrRow.getAttribute("DbResultFreightCarrierCode"); // �^���Ǝ�(����)
      String resultShippingMethodCode = (String)hdrRow.getAttribute("DbResultShippingMethodCode"); // �z���敪(����)
      Date   resultShippedDate        = (Date)hdrRow.getAttribute("DbResultShippedDate");          // �o�ɓ�(����)
      Date   resultArrivalDate        = (Date)hdrRow.getAttribute("DbResultArrivalDate");          // ���ɓ�(����)
      String dbShippingMethodCode     = (String)hdrRow.getAttribute("DbShippingMethodCode");       // �z���敪(DB)
      Number planFreightCarrierId     = (Number)hdrRow.getAttribute("PlanFreightCarrierId");       // �^���Ǝ�ID(�\��)
      String planFreightCarrierCode   = (String)hdrRow.getAttribute("PlanFreightCarrierCode");     // �^���Ǝ�(�\��)

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId)); // �����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));  // �ڋqID
      cstmt.setString(i++, customerCode);                    // �ڋq
      cstmt.setString(i++, instructions);                    // �E�v
      // ���сF���͂̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(resultFreightCarrierCode))
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(planFreightCarrierId)); // �^���Ǝ�ID
        cstmt.setString(i++, planFreightCarrierCode); // �^���Ǝ�
      // ���сF�����́A�\��F���͂̏ꍇ
      } else if ( XxcmnUtility.isBlankOrNull(resultFreightCarrierCode)
       && !XxcmnUtility.isBlankOrNull(freightCarrierCode)) 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(freightCarrierId)); // �^���Ǝ�ID
        cstmt.setString(i++, freightCarrierCode); // �^���Ǝ�
      // ���сF�����́A�\��F���͂̏ꍇ
      } else if (XxcmnUtility.isBlankOrNull(freightCarrierCode))
      {
        cstmt.setNull(i++, Types.INTEGER); // �^���Ǝ�ID
        cstmt.setNull(i++, Types.VARCHAR); // �^���Ǝ�
      }
      // �z���敪(����)�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(resultShippingMethodCode)) 
      {
        cstmt.setString(i++, shippingMethodCode);   // �z���敪
      } else 
      {
        cstmt.setString(i++, dbShippingMethodCode); // �z���敪(DB)
      }
      // �o�ɓ�(����)�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(resultShippedDate)) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate)); // �o�ɓ�  
      } else 
      {
        cstmt.setNull(i++, Types.DATE); // �o�ɓ�
      }
      // ���ɓ�(����)�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(resultArrivalDate)) 
      {
        cstmt.setDate(i++, XxcmnUtility.dateValue(arrivalDate)); // ���ɓ�  
      } else 
      {
        cstmt.setNull(i++, Types.DATE); // ���ɓ�
      }
      cstmt.setString(i++, freightChargeClass);                   // �^���敪
      cstmt.setString(i++, fixClass);                             // ���z�m��
      cstmt.setString(i++, takebackClass);                        // ����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // �o�ɑq��ID
      cstmt.setString(i++, shipWhseCode);                         // �o�ɑq��
      cstmt.setString(i++, arrivalTimeFrom);                      // ���׎���From
      cstmt.setString(i++, arrivalTimeTo);                        // ���׎���To
      if (XxcmnUtility.isBlankOrNull(designatedItemId)) 
      {
        cstmt.setNull(i++, Types.NUMERIC); // �����i��ID(INV)

      } else 
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(designatedItemId)); // �����i��ID(INV)

      }
      cstmt.setString(i++, designatedItemCode);                   // �����i��No
      cstmt.setDate(i++, XxcmnUtility.dateValue(designatedProdDate)); // ������
      cstmt.setString(i++, designatedBranchNo);                       // �����ԍ�
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumQuantity));   // ���v����
      cstmt.setString(i++, XxcmnUtility.stringValue(smallQuantity));  // ������
      cstmt.setString(i++, XxcmnUtility.stringValue(labelQuantity));  // ���x������
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyWeight));   // �d�ʐύڌ���
      cstmt.setString(i++, XxcmnUtility.commaRemoval(efficiencyCapacity)); // �e�ϐύڌ���
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedWeight));   // ��{�d��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(basedCapacity)); // ��{�e��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumWeight));     // �ύڏd�ʍ��v
      cstmt.setString(i++, XxcmnUtility.commaRemoval(sumCapacity));   // �ύڗe�ύ��v
      cstmt.setString(i++, reqDeptCode);                          // �˗�����
      cstmt.setString(i++, instDeptCode);                         // �w������
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // �����ID
      cstmt.setString(i++, vendorCode);                           // �����
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // �z����ID
      cstmt.setString(i++, shipToCode);                           // �z����
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr 

  /*****************************************************************************
   * �󒍖��׃A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @param insRow - �}���Ώۍs
   * @throws OAException - OA��O
   ****************************************************************************/
  public void insertOrderLine(
    OARow hdrRow,
    OARow insRow
    ) throws OAException
  {
    String apiName      = "insertOrderLine";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_lines_all( ");
    sb.append("    order_line_id "              ); // �󒍖��׃A�h�I��ID
    sb.append("   ,order_header_id "            ); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,order_line_number "          ); // ���הԍ�
    sb.append("   ,request_no "                 ); // �˗�No
    sb.append("   ,shipping_inventory_item_id " ); // �o�וi��ID
    sb.append("   ,shipping_item_code "         ); // �o�וi��
    sb.append("   ,quantity "                   ); // ����
    sb.append("   ,uom_code "                   ); // �P��
    sb.append("   ,based_request_quantity "     ); // ���_�˗�����
    sb.append("   ,request_item_id "            ); // �˗��i��ID
    sb.append("   ,request_item_code "          ); // �˗��i��
    sb.append("   ,futai_code "                 ); // �t�уR�[�h
    sb.append("   ,delete_flag "                ); // �폜�t���O
    sb.append("   ,line_description "           ); // �E�v
    sb.append("   ,unit_price "                 ); // �P��
    sb.append("   ,weight "                     ); // �d��
    sb.append("   ,capacity "                   ); // �e��
    sb.append("   ,created_by "                 ); // �쐬��
    sb.append("   ,creation_date "              ); // �쐬��
    sb.append("   ,last_updated_by "            ); // �ŏI�X�V��
    sb.append("   ,last_update_date "           ); // �ŏI�X�V��
    sb.append("   ,last_update_login) "         ); // �ŏI�X�V���O�C��
    sb.append("  VALUES( ");
    sb.append("    xxwsh_order_lines_all_s1.NEXTVAL ");
    sb.append("   ,:1  ");
    sb.append("   ,:2  ");
    sb.append("   ,:3  ");
    sb.append("   ,:4  ");
    sb.append("   ,:5  ");
    sb.append("   ,TO_NUMBER(:6)  ");
    sb.append("   ,:7  ");
    sb.append("   ,:8  ");
    sb.append("   ,:9  ");
    sb.append("   ,:10 ");
    sb.append("   ,:11 ");
    sb.append("   ,'N' ");
    sb.append("   ,:12 ");
    sb.append("   ,TO_NUMBER(:13) ");
    sb.append("   ,TO_NUMBER(:14) ");
    sb.append("   ,TO_NUMBER(:15) ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.USER_ID ");
    sb.append("   ,SYSDATE ");
    sb.append("   ,FND_GLOBAL.LOGIN_ID); ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number orderHeaderId   = (Number)hdrRow.getAttribute("OrderHeaderId");   // �󒍃w�b�_�A�h�I��ID
      Number orderLineNumber = (Number)insRow.getAttribute("OrderLineNumber"); // ���הԍ�
      String requestNo       = (String)hdrRow.getAttribute("RequestNo");       // �˗�No
      Number invItemId       = (Number)insRow.getAttribute("InvItemId");       // �o�וi��ID
      String itemNo          = (String)insRow.getAttribute("ItemNo");          // �o�וi��
      String instQuantity    = (String)insRow.getAttribute("InstQuantity");    // ����
      String itemUm          = (String)insRow.getAttribute("ItemUm");          // �P��
      String reqQuantity     = (String)insRow.getAttribute("ReqQuantity");     // ���_�˗�����
      Number whseInvItemId   = (Number)insRow.getAttribute("WhseInvItemId");   // �˗��i��ID
      String whseItemNo      = (String)insRow.getAttribute("WhseItemNo");      // �˗��i��
      String futaiCode       = (String)insRow.getAttribute("FutaiCode");       // �t�уR�[�h
      String lineDescription = (String)insRow.getAttribute("LineDescription"); // �E�v
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)insRow.getAttribute("UnitPriceNum")); // �P��
      String weight          = (String)insRow.getAttribute("Weight");          // �d��
      String capacity        = (String)insRow.getAttribute("Capacity");        // �e��
      
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));       // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineNumber));     // ���הԍ�
      cstmt.setString(i++, requestNo);                               // �˗�No
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));           // �o�וi��ID
      cstmt.setString(i++, itemNo);                                  // �o�וi��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity)); // ����
      cstmt.setString(i++, itemUm);                                  // �P��
      cstmt.setString(i++, reqQuantity);                             // ���_�˗�����
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));       // �˗��i��ID
      cstmt.setString(i++, whseItemNo);                              // �˗��i��
      cstmt.setString(i++, futaiCode);                               // �t�уR�[�h
      cstmt.setString(i++, lineDescription);                         // �E�v
      cstmt.setString(i++, unitPrice);                               // �P��
      cstmt.setString(i++, weight);                                  // �d��
      cstmt.setString(i++, capacity);                                // �e��
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine 

  /*****************************************************************************
   * �󒍖��׃A�h�I���̃f�[�^���X�V���܂��B
   * @param updRow - �X�V�Ώۍs
   * @throws OAException - OA��O
   ****************************************************************************/
  public void updateOrderLine(
    OARow updRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.shipping_inventory_item_id = :1 " ); // �o�וi��ID
    sb.append("        ,xola.shipping_item_code         = :2 " ); // �o�וi��
    sb.append("        ,xola.quantity                   = TO_NUMBER(:3) "); // ����
    sb.append("        ,xola.uom_code                   = :4 " ); // �P��
    sb.append("        ,xola.based_request_quantity     = :5 " ); // ���_�˗�����
    sb.append("        ,xola.request_item_id            = :6 " ); // �˗��i��ID
    sb.append("        ,xola.request_item_code          = :7 " ); // �˗��i��
    sb.append("        ,xola.futai_code                 = :8 " ); // �t�уR�[�h
    sb.append("        ,xola.line_description           = :9 " ); // �E�v
    sb.append("        ,xola.unit_price                 = TO_NUMBER(:10) "); // �P��
    sb.append("        ,xola.weight                     = TO_NUMBER(:11) "); // �d��
    sb.append("        ,xola.capacity                   = TO_NUMBER(:12) "); // �e��
    sb.append("        ,xola.last_updated_by            = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date           = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login          = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xola.order_line_id = :13 ;"); // �󒍖��׃A�h�I��ID
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number invItemId       = (Number)updRow.getAttribute("InvItemId");       // �o�וi��ID
      String itemNo          = (String)updRow.getAttribute("ItemNo");          // �o�וi��
      String instQuantity    = (String)updRow.getAttribute("InstQuantity");    // ����
      String itemUm          = (String)updRow.getAttribute("ItemUm");          // �P��
      String reqQuantity     = (String)updRow.getAttribute("ReqQuantity");     // ���_�˗�����
      Number whseInvItemId   = (Number)updRow.getAttribute("WhseInvItemId");   // �˗��i��ID
      String whseItemNo      = (String)updRow.getAttribute("WhseItemNo");      // �˗��i��
      String futaiCode       = (String)updRow.getAttribute("FutaiCode");       // �t�уR�[�h
      String lineDescription = (String)updRow.getAttribute("LineDescription"); // �E�v
      Number orderLineId     = (Number)updRow.getAttribute("OrderLineId");     // �󒍖��׃A�h�I��ID
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)updRow.getAttribute("UnitPriceNum")); // �P��
      String weight          = (String)updRow.getAttribute("Weight");          // �d��
      String capacity        = (String)updRow.getAttribute("Capacity");        // �e��
      
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));            // �o�וi��ID
      cstmt.setString(i++, itemNo);                                   // �o�וi��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity));  // ����
      cstmt.setString(i++, itemUm);                                   // �P��
      cstmt.setString(i++, reqQuantity);                              // ���_�˗�����
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));        // �˗��i��ID
      cstmt.setString(i++, whseItemNo);                               // �˗��i��
      cstmt.setString(i++, futaiCode);                                // �t�уR�[�h
      cstmt.setString(i++, lineDescription);                          // �E�v
      cstmt.setString(i++, unitPrice);                                // �P��
      cstmt.setString(i++, weight);                                   // �d��
      cstmt.setString(i++, capacity);                                 // �e��
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));          // �󒍖��׃A�h�I��ID
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO440001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /***************************************************************************
   * �˗������w�����փR�s�[���郁�\�b�h�ł��B
   ***************************************************************************
   */
  public void doCopyReqQty()
  {
    // �x���w���쐬���׏��VO�擾
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    Row[] rows = vo.getAllRowsInRange();
    if ((rows != null) || (rows.length > 0)) 
    {
      OARow row       = null;
      String reqQty   = null;
      String dbReqQty = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        reqQty   = (String)row.getAttribute("ReqQuantity");   // �˗���
        dbReqQty = (String)row.getAttribute("DbReqQuantity"); // DB�˗���
        // �˗������ύX���ꂽ�ꍇ
// 2008-10-21 D.Nihei MOD START
//        if (!XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
        if ( XxcmnUtility.isBlankOrNull(dbReqQty) 
         || !XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
// 2008-10-21 D.Nihei MOD END
        {
          // �˗������w�����փR�s�[
          row.setAttribute("InstQuantity", reqQty);
        }
      }
    }
  } // doCopyReqQty

  /***************************************************************************
   * �s�}���������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void addRow(String exeType)
  {
    OARow maxRow = null;  
    Number maxOrderLineNumber = new Number(0); // �ő喾�הԍ�

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow   = (OARow)hdrVo.first();
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

    // �x���w���쐬���׏��VO�擾
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // �ő�̖��הԍ��̎擾
    maxRow = (OARow)vo.last();

    // ���R�[�h�����݂���ꍇ
    if (maxRow != null) 
    {
      maxOrderLineNumber = (Number)maxRow.getAttribute("OrderLineNumber");

    }
    // �s�}��
    OARow row = (OARow)vo.createRow();

    // Switcher�̐���
    row.setAttribute("ItemSwitcher"   , "ItemNo");            // �i�ڐ���
    // �N���^�C�v���u12�F�p�b�J�[��O���H��p�v�̏ꍇ
    if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
    {
      row.setAttribute("FutaiSwitcher"  , "FutaiDisable");    // �t�ѐ���
    } else 
    {
      row.setAttribute("FutaiSwitcher"  , "FutaiCode");       // �t�ѐ���
    }
    row.setAttribute("ReqSwitcher"    , "ReqQuantity");       // �˗�������
    row.setAttribute("DescSwitcher"   , "LineDescription");   // ���l����
    row.setAttribute("ShippedSwitcher", "ShippedIconDisable");// �o�׎��уA�C�R������
    row.setAttribute("ShipToSwitcher" , "ShipToIconDisable"); // ���Ɏ��уA�C�R������
    row.setAttribute("ReserveSwitcher", "ReserveIconDisable");// �������A�C�R������
    row.setAttribute("DeleteSwitcher" , "DeleteEnable");      // �폜�A�C�R������

    // �f�t�H���g�l�̐ݒ�
    row.setAttribute("RecordType"     , XxcmnConstants.STRING_Y);    // ���R�[�h�^�C�v�F�V�K
    row.setAttribute("FutaiCode"      , XxcmnConstants.STRING_ZERO); // �t�сF0
    row.setAttribute("OrderLineNumber", maxOrderLineNumber.add(1));  // ���הԍ��F�ő�̖��הԍ�+1
    row.setAttribute("OrderHeaderId"  , orderHeaderId);              // �󒍃w�b�_�A�h�I��ID
    vo.last();
    vo.next();
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);
    // �ύX�Ɋւ���x����ݒ�
    super.setWarnAboutChanges();  

  } // addRow

  /***************************************************************************
   * �x���w���w�b�_��ʂ̃R�~�b�g�E�Č����������s�����\�b�h�ł��B
   * @param reqNo - �˗�No
   ***************************************************************************
   */
  public void doCommit(String reqNo)
  {
    // �R�~�b�g���s
    XxpoUtility.commit(getOADBTransaction());

    // �x���˗��v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String exeType = (String)srow.getAttribute("ExeType");

    // �w�b�_�̍Č������s���܂��B
    doSearchHdr(reqNo);

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �x���w���쐬�w�b�_PVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    OARow prow = (OARow)pvo.first();

    // �X�V�����ڐ���
    handleEventUpdHdr(exeType, prow, hdrRow);

    // ���ׂ̍Č������s���܂��B
    doSearchLine(exeType);

  } // doCommit

  /***************************************************************************
   * �m�菈���̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }

    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u���͒��v�ȊO�̏ꍇ 
    if (!XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }
  } // chkFix

  /***************************************************************************
   * ��̏����̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkRcv(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));

    }

    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u���͊����v�ȊO�̏ꍇ 
    if (!XxpoConstants.PROV_STATUS_NRK.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }
// 2008-10-21 D.Nihei ADD START T_TE080_BPO_440 No14
    String autoCreatePoClass = (String)row.getAttribute("AutoCreatePoClass"); // ���������쐬�敪
    String purchaseCode      = (String)row.getAttribute("PurchaseCode");      // �d����R�[�h
    String shipWhseCode      = (String)row.getAttribute("ShipWhseCode");      // �o�ɑq��
    // �o�ɑq�ɂɔ���t���d����R�[�h���ݒ肳��Ă��邩�`�F�b�N����B 
    if ("1".equals(autoCreatePoClass) && XxcmnUtility.isBlankOrNull(purchaseCode))
    {
      //�g�[�N���𐶐����܂��B
      MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM,
                                                 "�o�ɑq�ɂɕR�t���d����") };
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipWhseCode",
                            shipWhseCode,
                            XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10013,
                            tokens));
          
    }
// 2008-10-21 D.Nihei ADD END
  } // chkRcv

  /***************************************************************************
   * �蓮�w���m�菈���̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @param listFlag - �ꗗ�t���O true:�ꗗ��ʁAfalse:�w�b�_���
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkManualFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    boolean listFlag
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
    
    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u��̍ρv�A�u����v�ȊO�̏ꍇ 
    if (!XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // �ʒm�X�e�[�^�X�`�F�b�N���s���܂��B
    String notifStatus = (String)row.getAttribute("NotifStatus");    // �ʒm�X�e�[�^�X
    // �X�e�[�^�X���u��́v�̏ꍇ
    if (XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus))
    {
      // �ʒm�X�e�[�^�X���u���ʒm�v�A�u�Ēʒm�v�v�ȊO�̏ꍇ
      if (!XxpoConstants.NOTIF_STATUS_MTT.equals(notifStatus)
       && !XxpoConstants.NOTIF_STATUS_STY.equals(notifStatus)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "NotifStatus",
                              notifStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10124));

      }
      // �z�ԁE�����σ`�F�b�N���s���܂��B
      String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // �^���敪
      String shipToNo           = (String)row.getAttribute("ShipToNo");           // �z��No
      Number orderType          = (Number)row.getAttribute("OrderTypeId");        // �����敪
      // �^���敪���u�Ώہv�ŁA�z��No���ݒ肳��Ă��Ȃ��ꍇ
      if (XxcmnConstants.OBJECT_ON.equals(freightChargeClass)
       && XxcmnUtility.isBlankOrNull(shipToNo)) 
      {
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROC_NAME,
                                                   XxpoConstants.TOKEN_NAME_CAREERS) };
        if (listFlag) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OrderTypeId",
                                orderType,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        } else 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ShipToNo",
                                shipToNo,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));

        }
      }
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      // �����σ`�F�b�N
      if (!XxpoUtility.chkAllOrderReserved(getOADBTransaction(),
                                           orderHeaderId)) 
      {
        //�g�[�N���𐶐����܂��B
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROC_NAME,
                                                   XxpoConstants.TOKEN_NAME_RESERVE) };
        if (listFlag) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "OrderTypeId",
                                orderType,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        } else 
        {
          exceptions.add( new OAException(
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10128,
                                tokens));
        
        }
      }
    // �X�e�[�^�X���u����v�̏ꍇ
    } else if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      // �ʒm�X�e�[�^�X���u�Ēʒm�v�v�ȊO�̏ꍇ
      if (!XxpoConstants.NOTIF_STATUS_STY.equals(notifStatus)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "NotifStatus",
                              notifStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10124));

      }
    }
  } // chkManualFix

  /***************************************************************************
   * ���z�m�菈���̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkAmountFix(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
// 2009-01-20 v1.12 T.Yoshimoto Mod Start �{��#985
/*
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
*/
    Date arrivalDate = getUpdateArrivalDate(row); // ���ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  arrivalDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }
// 2009-01-20 v1.12 T.Yoshimoto Mod End �{��#985

    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u�o�׎��ьv��ρv�ȊO�̏ꍇ 
    if (!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // ���z�m��σ`�F�b�N���s���܂��B
    String fixClass  = (String)row.getAttribute("FixClass");    // �L�����z�m��敪
    Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
    // �L�����z�m��敪���u�m��v�̏ꍇ
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "OrderTypeId",
                            orderType,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10125));

    }
  } // chkAmountFix

  /***************************************************************************
   * ���i�ݒ菈���̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @param listFlag - �ꗗ�t���O true:�ꗗ��ʁAfalse:�w�b�_���
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkPriceSet(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    boolean listFlag
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate"); // ���ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(), arrivalDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));
    }

    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u����v�̏ꍇ
    if (XxpoConstants.PROV_STATUS_CAN.equals(transStatus)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "TransStatus",
                            transStatus,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10145));
          
    }

    // ���z�m��σ`�F�b�N���s���܂��B
    String fixClass  = (String)row.getAttribute("FixClass");    // �L�����z�m��敪
    Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
    // �L�����z�m��敪���u�m��v�̏ꍇ
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      if (listFlag) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "OrderTypeId",
                              orderType,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10125));

        
      } else 
      {
        exceptions.add( new OAException(
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10125));
        
      }
    }
  } // chkPriceSet

  /***************************************************************************
   * ���փ{�^���������̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkNext(
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // �V�K�t���O
    Object newFlag = row.getAttribute("NewFlag");    
    // �˗�����
    Object reqDeptCode = row.getAttribute("ReqDeptCode");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(reqDeptCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqDeptCode",
                            reqDeptCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // �w������
    Object instDeptCode = row.getAttribute("InstDeptCode");
    // �X�V���̂ݕK�{�`�F�b�N
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnUtility.isBlankOrNull(instDeptCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "InstDeptCode",
                            instDeptCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // �����
    Object vendorCode = row.getAttribute("VendorCode");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(vendorCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "VendorCode",
                            vendorCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // �z����
    Object shipToCode = row.getAttribute("ShipToCode");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(shipToCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipToCode",
                            shipToCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
    }

    // �o�ɑq��
    Object shipWhseCode = row.getAttribute("ShipWhseCode");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(shipWhseCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShipWhseCode",
                            shipWhseCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
    }

    // �^���Ǝ�
    Object freightCarrierCode = row.getAttribute("FreightCarrierCode");
    String freightChargeClass = (String)row.getAttribute("FreightChargeClass"); // �^���敪
    // �X�V�����^���敪���u�Ώہv�̏ꍇ�̂ݕK�{�`�F�b�N
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnConstants.OBJECT_ON.equals(freightChargeClass)
     && XxcmnUtility.isBlankOrNull(freightCarrierCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FreightCarrierCode",
                            freightCarrierCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // �o�ɓ�
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // �X�V���̂ݕK�{�`�F�b�N
    if (XxcmnConstants.STRING_N.equals(newFlag)
     && XxcmnUtility.isBlankOrNull(shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    }

    // ���ɓ�
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

    // �o�ɓ������͂���Ă���ꍇ
    } else if (!XxcmnUtility.isBlankOrNull(shippedDate))
    {
// 2008-10-21 D.Nihei Add START
      // ���ѓ�(�o�ɓ��A���ɓ�)���擾���܂��B
      Date resultShippedDate = (Date)row.getAttribute("ResultShippedDate"); // �o�ɓ�
      Date resultArrivalDate = (Date)row.getAttribute("ResultArrivalDate"); // ���ɓ�
      // ���ѓ����������͂���Ă���ꍇ�܂��͗������͂���Ă��Ȃ��ꍇ
      if ( XxcmnUtility.isBlankOrNull(resultShippedDate) 
       &&  XxcmnUtility.isBlankOrNull(resultArrivalDate))
      {
// 2008-10-21 D.Nihei Add END
        // �o�ɓ������ɓ��̏ꍇ
        if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ShippedDate",
                                shippedDate,
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10118));

        }
// 2008-10-21 D.Nihei Add START
      }
// 2008-10-21 D.Nihei Add END
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkNext

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkOrderLine(String exeType) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList

    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            hdrVo.getName(),
                            hdrRow.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10119));

    }

    // �P�����o�ۂ𔻒f���܂��B
    boolean priceFlag = false;
    Date arrivalDate  = (Date)hdrRow.getAttribute("ArrivalDate"); // ���ɓ�
    Object vendorCode = hdrRow.getAttribute("VendorCode");        // �����
    // ���ɓ��E�����̏ꍇ
    if (!XxcmnUtility.isEquals(arrivalDate, hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(vendorCode,  hdrRow.getAttribute("DbVendorCode")) ) 
    {
      priceFlag = true;  

    }
    //�x���w���v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // ��\���i�\      
    String listIdVendor    = (String)hdrRow.getAttribute("PriceList");    // ����承�i�\ID
    
    // �����Ώۂ��擾���܂��B
    XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();
    // �X�V�s�擾
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        updRow = (OARow)updRows[i];

        // �i�ڂ��ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(updRow.getAttribute("ItemId"), 
                                   updRow.getAttribute("DbItemId"))) 
        {
          priceFlag = true;   
        }
        
        // �X�V�`�F�b�N����
        if (!chkOrderLineUpd(hdrRow, vo, updRow, exceptions))
        {
          // ���ד��o����
          getLineData(vo,
                      updRow,
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
                      shippedDate,
// 2008-10-07 H.Itou Add End
                      arrivalDate,
                      listIdRepresent,
                      listIdVendor,
                      priceFlag,
                      exceptions);
        }
      }
    }
    // �}���s�擾
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        insRow = (OARow)insRows[i];

        // �}���`�F�b�N����
        if (!chkOrderLineIns(hdrRow, vo, insRow, exceptions, exeType))
        {
          if (!(XxcmnUtility.isBlankOrNull(insRow.getAttribute("ItemNo"))
           && XxcmnUtility.isBlankOrNull(insRow.getAttribute("ReqQuantity"))
           && XxcmnUtility.isBlankOrNull(insRow.getAttribute("LineDescription")))) 
          {
            // �P�����o�t���O��true�ɂ���
            priceFlag = true;  
            // ���ד��o����
            getLineData(vo,
                        insRow,
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
                        shippedDate,
// 2008-10-07 H.Itou Add End
                        arrivalDate,
                        listIdRepresent,
                        listIdVendor,
                        priceFlag,
                        exceptions);
          }
        }
      }
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkOrderLine

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B(�X�V�p)
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @param vo     - �r���[�I�u�W�F�N�g
   * @param row    - ���׍s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @return boolean - �G���[�t���O true:�G���[�L
   *                              false:�G���[��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkOrderLineUpd(
    OARow hdrRow,
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean errFlag = false; // �G���[�����t���O

    // �����擾
    Object orderLineNum = row.getAttribute("OrderLineNumber"); // ���הԍ�
    Object itemNo       = row.getAttribute("ItemNo");          // �i�ڃR�[�h
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(itemNo)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ItemNo",
                            itemNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else
    {
      // �d���L���i�ڃ`�F�b�N
      String lotCtl            = (String)row.getAttribute("LotCtl");               // ���b�g�Ǘ��敪
      String autoCreatePoClass = (String)hdrRow.getAttribute("AutoCreatePoClass"); // ���������쐬�敪
      // ���������쐬�敪���u1�F�����v�ŁA�u���b�g�Ǘ��Ώہv�̏ꍇ
      if ("1".equals(autoCreatePoClass) && XxpoConstants.LOT_CTL_1.equals(lotCtl)) 
      {
        // �d���L���i�ڃ`�F�b�N�G���[ 
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10031));
        errFlag = true;

      } else
      {
        // �`�F�b�N�p�S�s�擾
        Row[] chkRows = vo.getAllRowsInRange();
        // �X�V�s�̖��׌�����1�������Ȃ��ꍇ
        if ((chkRows != null) || (chkRows.length >0)) 
        {
          OARow chkRow = null;
          for (int i = 0; i < chkRows.length; i++)
          {
            // i�Ԗڂ̍s���擾
            chkRow = (OARow)chkRows[i];
            // �i�ڏd���`�F�b�N(���̃��R�[�h�ƕi�ڂ�����̏ꍇ)
            if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))
              && XxcmnUtility.isEquals(itemNo      , chkRow.getAttribute("ItemNo"))) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ItemNo",
                                    itemNo,
                                    XxcmnConstants.APPL_XXPO, 
                                    XxpoConstants.XXPO10151));
              errFlag = true;
              break;
            }
          }
        }
      }
    }

    Object futaiCode = row.getAttribute("FutaiCode");       // �t�уR�[�h
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(futaiCode)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FutaiCode",
                            futaiCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));

      errFlag = true;

    }

    Object reqQuantity = row.getAttribute("ReqQuantity");       // �˗�����
    // �K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(reqQuantity)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqQuantity",
                            reqQuantity,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else 
    {
      // ���l�`�F�b�N
      if (!XxcmnUtility.chkNumeric(reqQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ReqQuantity",
                              reqQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;

      } else
      {
        // ���ʃ`�F�b�N
        if (!XxcmnUtility.chkCompareNumeric(2, reqQuantity, XxcmnConstants.STRING_ZERO)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ReqQuantity",
                                reqQuantity,
                                XxcmnConstants.APPL_XXPO,         
                                XxpoConstants.XXPO10153));
          errFlag = true;

        }
      }
    }
    return errFlag;
    
  } // chkOrderLineUpd

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B(�}���p)
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @param vo     - �r���[�I�u�W�F�N�g
   * @param row    - ���׍s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @param exeType - �N���^�C�v
   * @return boolean - �G���[�t���O true:�G���[�L
   *                              false:�G���[��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkOrderLineIns(
    OARow hdrRow,
    OAViewObjectImpl vo,
    OARow row,
    ArrayList exceptions,
    String exeType
    ) throws OAException
  {
    boolean errFlag = false; // �G���[�����t���O

    // �����擾
    Object orderLineNum = row.getAttribute("OrderLineNumber"); // ���הԍ�
    Object itemNo       = row.getAttribute("ItemNo");          // �i�ڃR�[�h
    Object futaiCode    = row.getAttribute("FutaiCode");       // �t�уR�[�h
    Object reqQuantity  = row.getAttribute("ReqQuantity");     // �˗�����
    Object description  = row.getAttribute("LineDescription"); // ���l

    // �S�ē��͂���Ă��Ȃ���΃`�F�b�N���Ȃ�
    if (XxcmnUtility.isBlankOrNull(itemNo)
     && (XxcmnUtility.isBlankOrNull(futaiCode) || XxpoConstants.EXE_TYPE_12.equals(exeType))
     && XxcmnUtility.isBlankOrNull(reqQuantity)
     && XxcmnUtility.isBlankOrNull(description)) 
    {
      return errFlag;  

    }
    
    // �K�{�`�F�b�N(�i��)
    if (XxcmnUtility.isBlankOrNull(itemNo)
     && ((!XxcmnUtility.isBlankOrNull(futaiCode) && !XxpoConstants.EXE_TYPE_12.equals(exeType))
      || !XxcmnUtility.isBlankOrNull(reqQuantity)
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ItemNo",
                            itemNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else
    {
      // �d���L���i�ڃ`�F�b�N
      String lotCtl            = (String)row.getAttribute("LotCtl");               // ���b�g�Ǘ��敪
      String autoCreatePoClass = (String)hdrRow.getAttribute("AutoCreatePoClass"); // ���������쐬�敪
      // ���������쐬�敪���u1�F�����v�ŁA�u���b�g�Ǘ��Ώہv�̏ꍇ
      if ("1".equals(autoCreatePoClass) && XxpoConstants.LOT_CTL_1.equals(lotCtl)) 
      {
        // �d���L���i�ڃ`�F�b�N�G���[ 
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10031));
        errFlag = true;

      } else
      {
        // �`�F�b�N�p�S�s�擾
        Row[] chkRows = vo.getAllRowsInRange();
        // �X�V�s�̖��׌�����1�������Ȃ��ꍇ
        if ((chkRows != null) || (chkRows.length >0)) 
        {
          OARow chkRow = null;
          for (int i = 0; i < chkRows.length; i++)
          {
            // i�Ԗڂ̍s���擾
            chkRow = (OARow)chkRows[i];
            // �i�ڏd���`�F�b�N(���̃��R�[�h�ƕi�ڂ�����̏ꍇ)
            if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))
              && XxcmnUtility.isEquals(itemNo      , chkRow.getAttribute("ItemNo"))) 
            {
              exceptions.add( new OAAttrValException(
                                    OAAttrValException.TYP_VIEW_OBJECT,          
                                    vo.getName(),
                                    row.getKey(),
                                    "ItemNo",
                                    itemNo,
                                    XxcmnConstants.APPL_XXPO, 
                                    XxpoConstants.XXPO10151));
              errFlag = true;

              break;

            }
          }
        }
      }
    }

    // �K�{�`�F�b�N(�t��)
    if (XxcmnUtility.isBlankOrNull(futaiCode)
     && (!XxcmnUtility.isBlankOrNull(itemNo)
      || !XxcmnUtility.isBlankOrNull(reqQuantity)
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "FutaiCode",
                            futaiCode,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    }

    // �K�{�`�F�b�N(�˗���)
    if (XxcmnUtility.isBlankOrNull(reqQuantity)
     && (!XxcmnUtility.isBlankOrNull(itemNo)
      || (!XxcmnUtility.isBlankOrNull(futaiCode) && !XxpoConstants.EXE_TYPE_12.equals(exeType))
      || !XxcmnUtility.isBlankOrNull(description))) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ReqQuantity",
                            reqQuantity,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10002));
      errFlag = true;

    } else 
    {
      // ���l�`�F�b�N
      if (!XxcmnUtility.chkNumeric(reqQuantity, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ReqQuantity",
                              reqQuantity,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;

      } else
      {

        // ���ʃ`�F�b�N
        if (!XxcmnUtility.chkCompareNumeric(2, reqQuantity, XxcmnConstants.STRING_ZERO)) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                vo.getName(),
                                row.getKey(),
                                "ReqQuantity",
                                reqQuantity,
                                XxcmnConstants.APPL_XXPO,         
                                XxpoConstants.XXPO10153));
          errFlag = true;
        }
      }
    }
    return errFlag;

  } // chkOrderLineIns

  /***************************************************************************
   * �폜�����̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo     - �r���[�I�u�W�F�N�g
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @param row    - ���׍s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkOrderLineDel(
    OAViewObjectImpl vo,
    OARow hdrRow,
    OARow row
    ) throws OAException
  {
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      throw new OAException(
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10119);

    }
  } // chkOrderLineDel

  /***************************************************************************
   * ���b�N�E�r���������s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkLockAndExclusive(
    OAViewObjectImpl vo,
    OARow row
    ) throws OAException
  {
    // ���b�N���擾���܂��B
    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    Number orderType     = (Number)row.getAttribute("OrderTypeId");   // �����敪
    if (!XxpoUtility.getXxwshOrderLock(getOADBTransaction(), orderHeaderId)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // ���b�N�G���[���b�Z�[�W
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10138);

    }
    // �r���`�F�b�N���s���܂��B
    String xohaLastUpdateDate = (String)row.getAttribute("XohaLastUpdateDate"); // �ŏI�X�V���i�󒍃w�b�_�j
    String xolaLastUpdateDate = (String)row.getAttribute("XolaLastUpdateDate"); // �ŏI�X�V���i�󒍖��ׁj
    if (!XxpoUtility.chkExclusiveXxwshOrder(getOADBTransaction(),
                                            orderHeaderId,
                                            xohaLastUpdateDate,
                                            xolaLastUpdateDate)) 
    {
      XxpoUtility.rollBack(getOADBTransaction());
      // �r���G���[���b�Z�[�W
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "OrderTypeId",
                  orderType,
                  XxcmnConstants.APPL_XXCMN, 
                  XxcmnConstants.XXCMN10147);
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * �w�b�_���ڂ̓��o�������s�����\�b�h�ł��B
   * @param hdrVo  - �w�b�_�r���[�I�u�W�F�N�g
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getHdrData(
    OAViewObjectImpl hdrVo,
    OARow hdrRow
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList

    // �e������擾���܂��B
    Date arrivalDate     = (Date)hdrRow.getAttribute("ArrivalDate");          // ���ɓ� 
    Date shippedDate     = (Date)hdrRow.getAttribute("ShippedDate");          // �o�ɓ�
    String shipToCode    = (String)hdrRow.getAttribute("ShipToCode");         // �z����
    String shipWhseCode  = (String)hdrRow.getAttribute("ShipWhseCode");       // �o�ɑq��
    String freightCode   = (String)hdrRow.getAttribute("FreightCarrierCode"); // �^���Ǝ�
    String frequentMover = (String)hdrRow.getAttribute("FrequentMover");      // ��\�^�����
    String freightClass  = (String)hdrRow.getAttribute("FreightChargeClass"); // �^���敪
    Number orderTypeId   = (Number)hdrRow.getAttribute("OrderTypeId");        // �����敪
    String weightCapacityClass = (String)hdrRow.getAttribute("WeightCapacityClass"); // �d�ʗe�ϋ敪
    String autoCreatePoClass   = (String)hdrRow.getAttribute("AutoCreatePoClass");   // ���������쐬�敪

    // �w�������������͂̏ꍇ
    if (XxcmnUtility.isBlankOrNull(hdrRow.getAttribute("InstDeptCode"))) 
    {
      // �˗��������w�������փR�s�[
      hdrRow.setAttribute("InstDeptCode", hdrRow.getAttribute("ReqDeptCode"));  
      hdrRow.setAttribute("InstDeptName", hdrRow.getAttribute("ReqDeptName"));  
    }
    // �����敪���玩�������쐬�敪���擾
    autoCreatePoClass = XxpoUtility.getAutoCreatePoClass(
                          getOADBTransaction(),
                          orderTypeId);
    // ���������쐬�敪���i�[
    hdrRow.setAttribute("AutoCreatePoClass", autoCreatePoClass);

    // �o�ɓ������͂���Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(shippedDate)) 
    {
      shippedDate = XxpoUtility.getOprtnDay(
                      getOADBTransaction(),
                      XxcmnUtility.getDate(arrivalDate, -1),
                      shipWhseCode,
                      null,
                      0); 
      // ���o����Ȃ������ꍇ
      if (XxcmnUtility.isBlankOrNull(shippedDate)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              hdrVo.getName(),
                              hdrRow.getKey(),
                              "ShippedDate",
                              shippedDate,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10002));

      } else
      {
        // �o�ɓ��ɃZ�b�g
        hdrRow.setAttribute("ShippedDate", shippedDate);

      }
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // �^���敪���u�Ώہv�A���^���Ǝ҂����͂���Ă��Ȃ��ꍇ
    if (XxcmnConstants.STRING_ONE.equals(freightClass) && XxcmnUtility.isBlankOrNull(freightCode)) 
    {
      if (XxcmnUtility.isBlankOrNull(frequentMover)) 
      {
        exceptions.add( new OAException(
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10117));
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              hdrVo.getName(),
                              hdrRow.getKey(),
                              "FreightCarrierCode",
                              freightCode,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10002));

      } else 
      {
        Number freightId   = null;
        String freightname = null;
        // ��\�^����Ђ����ɎZ�o����B
        HashMap paramsRet = XxpoUtility.getfreightData(
                              getOADBTransaction(),
                              frequentMover,
                              freightId,
                              freightCode,
                              freightname,
                              shippedDate); 

        if (XxcmnUtility.isBlankOrNull(paramsRet.get("freightCode"))) 
        {
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,          
                                hdrVo.getName(),
                                hdrRow.getKey(),
                                "FreightCarrierCode",
                                paramsRet.get("freightCode"),
                                XxcmnConstants.APPL_XXPO, 
                                XxpoConstants.XXPO10002));

        } else 
        {
          // �^���Ǝ҂ɃZ�b�g
          hdrRow.setAttribute("FreightCarrierId"  , paramsRet.get("freightId"));
          hdrRow.setAttribute("FreightCarrierCode", paramsRet.get("freightCode"));
          hdrRow.setAttribute("FreightCarrierName", paramsRet.get("freightName"));

        }
      }
      // �G���[���������ꍇ�G���[���X���[���܂��B
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
  } // getHdrData

  /***************************************************************************
   * ���׍��ڂ̓��o�������s�����\�b�h�ł��B
   * @param vo  - ���׃r���[�I�u�W�F�N�g
   * @param row - ���׍s�I�u�W�F�N�g
   * @param shippedDate     - �o�ɓ�
   * @param arrivalDate     - ���ɓ�
   * @param listIdRepresent - ��\���i�\ID
   * @param listIdVendor    - ����承�i�\ID
   * @param priceFlag       - �P�����o�ۃt���O true:���s�Afalse:���s���Ȃ�
   * @param exceptions      - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getLineData(
    OAViewObjectImpl vo,
    OARow row,
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
    Date shippedDate,
// 2008-10-07 H.Itou Add End
    Date arrivalDate,
    String listIdRepresent,
    String listIdVendor,
    boolean priceFlag,
    ArrayList exceptions
    ) throws OAException
  {
    Number invItemId   = (Number)row.getAttribute("InvItemId");   // INV�i��ID
    String itemNo      = (String)row.getAttribute("ItemNo");      // �i��No
    String reqQuantity = (String)row.getAttribute("ReqQuantity"); // �˗���
    // �P�����o�t���O��true�A�܂��͕i�ڂ��ύX���ꂽ�ꍇ
    if (priceFlag) 
    {
      // �P�����o����  
      Number unitPrice = XxpoUtility.getUnitPrice(
                           getOADBTransaction(),
                           invItemId,
                           listIdVendor,
                           listIdRepresent,
                           arrivalDate,
                           itemNo);

      // �擾�ł��Ȃ������ꍇ
      if (XxcmnUtility.isBlankOrNull(unitPrice)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "ItemNo",
                              itemNo,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10201));

      } else
      {
        row.setAttribute("UnitPriceNum", unitPrice);

      }
    }
    // ���v�d�ʁE���v�e�ς̓��o
    HashMap retMap = XxpoUtility.calcTotalValue(
                       getOADBTransaction(),
                       itemNo,
                       XxcmnUtility.commaRemoval(reqQuantity),
// 2008-10-07 H.Itou Add Start �����e�X�g�w�E240
                       shippedDate
// 2008-10-07 H.Itou Add End
                       );
    String retCode = (String)retMap.get("retCode");
    // �߂�l���G���[�̏ꍇ
    if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
    {
       MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                  XxpoConstants.TOKEN_NAME_CALC_ERR) };
       exceptions.add( new OAAttrValException(
                             OAAttrValException.TYP_VIEW_OBJECT,          
                             vo.getName(),
                             row.getKey(),
                             "ItemNo",
                             itemNo,
                             XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN05002,
                             tokens));

    } else
    {
      // �d�ʁA�e�ςɃZ�b�g
      row.setAttribute("Weight",   (String)retMap.get("sumWeight"));
      row.setAttribute("Capacity", (String)retMap.get("sumCapacity"));

    }
  } // getLineData

  /***************************************************************************
   * �z�Ԋ֘A�����Z�b�g���郁�\�b�h�ł��B
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   ***************************************************************************
   */
  public void setCarriersData(OARow hdrRow)
  {
    /****************************
     * �w�b�_�e����擾
     ****************************/
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");      // �󒍃w�b�_�A�h�I��ID
    String freightClass  = (String)hdrRow.getAttribute("FreightChargeClass"); // �^���敪

    /****************************
     * �z�Ԋ֘A��񓱏o
     ****************************/
    HashMap retParams = XxpoUtility.getCarriersData(
                          getOADBTransaction(),
                          orderHeaderId);
    /****************************
     * �e���ڂ��Z�b�g
     ****************************/
    // �^���敪���u�Ώہv�̏ꍇ
    if (XxcmnUtility.isEquals(freightClass, XxcmnConstants.OBJECT_ON)) 
    {
      hdrRow.setAttribute("SmallQuantity", retParams.get("smallQuantity"));  // ������
      hdrRow.setAttribute("LabelQuantity", retParams.get("labelQuantity"));  // ���x������

    } else 
    {
      hdrRow.setAttribute("SmallQuantity", null);  // ������
      hdrRow.setAttribute("LabelQuantity", null);  // ���x������
      
    }
    hdrRow.setAttribute("SumQuantity",   retParams.get("sumQuantity"));    // ���v����
    hdrRow.setAttribute("SumWeight",     retParams.get("sumWeight"));      // ���v�d��
    hdrRow.setAttribute("SumCapacity",   retParams.get("sumCapacity"));    // ���v�e��

  } // setCarriersData

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param baseReqNo   - ���˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void initializeCopy(
    String exeType,
    String baseReqNo
    ) throws OAException
  {
    // �x���˗��v�񌟍�VO
    XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey",  new Number(1));
      srow.setAttribute("ExeType", exeType);
      //�v���t�@�C�������\���i�\ID�擾
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // ��\���i�\���擾�ł��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10113);
      }
      srow.setAttribute("RepPriceListId", repPriceListId);
    }
    // �x���w���쐬�w�b�_PVO
    XxpoProvisionInstMakeHeaderPVOImpl pvo = getXxpoProvisionInstMakeHeaderPVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0)
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));

    } else
    {
      prow = (OARow)pvo.first();
      // ������
      handleEventAllOnHdr(prow);

    }

    OARow hdrRow  = null;
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    if (hdrVo.getFetchedRowCount() == 0)
    {
      hdrVo.setMaxFetchSize(0);
      hdrVo.executeQuery();
      hdrVo.insertRow(hdrVo.createRow());
      hdrRow = (OARow)hdrVo.first();
      hdrRow.setNewRowState(OARow.STATUS_INITIALIZED);
    } else
    {
      hdrRow = (OARow)hdrVo.first();
    }

    // �L�[�̐ݒ�
    hdrRow.setAttribute("OrderHeaderId", new Number(-1));
    // �f�t�H���g�l�̐ݒ�
    hdrRow.setAttribute("NewFlag",             XxcmnConstants.STRING_Y);              // �V�K�t���O
    hdrRow.setAttribute("TransStatus",         XxpoConstants.PROV_STATUS_NRT);        // �X�e�[�^�X
    hdrRow.setAttribute("NotifStatus",         XxpoConstants.NOTIF_STATUS_MTT);       // �ʒm�X�e�[�^�X
    hdrRow.setAttribute("RcvClass",            XxpoConstants.RCV_CLASS_OFF);          // �w�����
    hdrRow.setAttribute("FixClass",            XxpoConstants.FIX_CLASS_OFF);          // ���z�m��

    // �x���w���쐬�R�s�[�w�b�_VO�擾
    XxpoProvCopyHeaderVOImpl copyHdrVo = getXxpoProvCopyHeaderVO1();
    copyHdrVo.initQuery(baseReqNo);
    copyHdrVo.first();
    // �R�s�[���̑Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((copyHdrVo == null)  || (copyHdrVo.getFetchedRowCount() == 0)) 
    {
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // ���փ{�^��
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }

    OARow copyHdrRow = (OARow)copyHdrVo.first(); 
    Number baseOrderHdrId = (Number)copyHdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    // �x���w���쐬�R�s�[����VO�擾
    XxpoProvCopyLineVOImpl copyLineVo = getXxpoProvCopyLineVO1();
    copyLineVo.initQuery(exeType, baseOrderHdrId);
    copyLineVo.first();
    // �R�s�[���̑Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((copyLineVo == null) || (copyLineVo.getFetchedRowCount() == 0)) 
    {
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
      prow.setAttribute("NextBtnReject", Boolean.TRUE); // ���փ{�^��
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);

    }

    // �w�b�_�R�s�[�������{
    hdrRow.setAttribute("AutoCreatePoClass",   copyHdrRow.getAttribute("AutoCreatePoClass"));  // ���������쐬�敪
    hdrRow.setAttribute("OrderTypeId",         copyHdrRow.getAttribute("OrderTypeId"));        // �����敪
    hdrRow.setAttribute("OrderTypeName",       copyHdrRow.getAttribute("OrderTypeName"));      // �����敪��
    hdrRow.setAttribute("WeightCapacityClass", copyHdrRow.getAttribute("WeightCapacityClass")); // �d�ʗe�ϋ敪
    hdrRow.setAttribute("BaseRequestNo",       copyHdrRow.getAttribute("RequestNo"));          // ���˗�No
    hdrRow.setAttribute("ReqDeptCode",         copyHdrRow.getAttribute("ReqDeptCode"));        // �˗�����
    hdrRow.setAttribute("ReqDeptName",         copyHdrRow.getAttribute("ReqDeptName"));        // �˗�������
    hdrRow.setAttribute("InstDeptCode",        copyHdrRow.getAttribute("InstDeptCode"));       // �w������
    hdrRow.setAttribute("InstDeptName",        copyHdrRow.getAttribute("InstDeptName"));       // �w��������
    hdrRow.setAttribute("VendorId",            copyHdrRow.getAttribute("VendorId"));           // �����ID
    hdrRow.setAttribute("VendorCode",          copyHdrRow.getAttribute("VendorCode"));         // �����R�[�h
    hdrRow.setAttribute("VendorName",          copyHdrRow.getAttribute("VendorName"));         // ����於
    hdrRow.setAttribute("ShipToId",            copyHdrRow.getAttribute("ShipToId"));           // �z����ID
    hdrRow.setAttribute("ShipToCode",          copyHdrRow.getAttribute("ShipToCode"));         // �z����R�[�h
    hdrRow.setAttribute("ShipToName",          copyHdrRow.getAttribute("ShipToName"));         // �z���於
    hdrRow.setAttribute("ShipWhseId",          copyHdrRow.getAttribute("ShipWhseId"));         // �o�ɑq��ID
    hdrRow.setAttribute("ShipWhseCode",        copyHdrRow.getAttribute("ShipWhseCode"));       // �o�ɑq�ɃR�[�h
    hdrRow.setAttribute("ShipWhseName",        copyHdrRow.getAttribute("ShipWhseName"));       // �o�ɑq�ɖ�
    hdrRow.setAttribute("FreightCarrierId",    copyHdrRow.getAttribute("FreightCarrierId"));   // �^���Ǝ�ID
    hdrRow.setAttribute("FreightCarrierCode",  copyHdrRow.getAttribute("FreightCarrierCode")); // �^���Ǝ҃R�[�h
    hdrRow.setAttribute("FreightCarrierName",  copyHdrRow.getAttribute("FreightCarrierName")); // �^���ƎҖ�
    hdrRow.setAttribute("ShippedDate",         copyHdrRow.getAttribute("ShippedDate"));        // �o�ɓ�
    hdrRow.setAttribute("ArrivalDate",         copyHdrRow.getAttribute("ArrivalDate"));        // ���ɓ�
    hdrRow.setAttribute("ArrivalTimeFrom",     copyHdrRow.getAttribute("ArrivalTimeFrom"));    // ���׎���From
    hdrRow.setAttribute("ArrivalTimeFromName", copyHdrRow.getAttribute("ArrivalTimeFromName"));// ���׎���From��
    hdrRow.setAttribute("ArrivalTimeTo",       copyHdrRow.getAttribute("ArrivalTimeTo"));      // ���׎���To
    hdrRow.setAttribute("ArrivalTimeToName",   copyHdrRow.getAttribute("ArrivalTimeToName"));  // ���׎���To��
    hdrRow.setAttribute("FreightChargeClass",  copyHdrRow.getAttribute("FreightChargeClass")); // �^���敪
    hdrRow.setAttribute("TakebackClass",       copyHdrRow.getAttribute("TakebackClass"));      // ����敪
    hdrRow.setAttribute("DesignatedProdDate",  copyHdrRow.getAttribute("DesignatedProdDate")); // ������
    hdrRow.setAttribute("DesignatedItemCode",  copyHdrRow.getAttribute("DesignatedItemCode")); // �����i�ڃR�[�h
    hdrRow.setAttribute("DesignatedItemName",  copyHdrRow.getAttribute("DesignatedItemName")); // �����i�ږ�
    hdrRow.setAttribute("DesignatedBranchNo",  copyHdrRow.getAttribute("DesignatedBranchNo")); // �����ԍ�
    hdrRow.setAttribute("ShippingInstructions", copyHdrRow.getAttribute("ShippingInstructions")); // �E�v
    hdrRow.setAttribute("DesignatedItemId",    copyHdrRow.getAttribute("DesignatedItemId"));   // �����i��ID
    hdrRow.setAttribute("FrequentMover",       copyHdrRow.getAttribute("FrequentMover"));      // ��\�^�����
    hdrRow.setAttribute("CustomerId",          copyHdrRow.getAttribute("CustomerId"));         // �ڋqID
    hdrRow.setAttribute("CustomerCode",        copyHdrRow.getAttribute("CustomerCode"));       // �ڋq�R�[�h
    hdrRow.setAttribute("PriceList",           copyHdrRow.getAttribute("PriceList"));          // ���i�\

    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    // �x���w���쐬����VO�擾
    XxpoProvisionInstMakeLineVOImpl lineVo = getXxpoProvisionInstMakeLineVO1();
    // ���������s���܂��B
    lineVo.initQuery(exeType, orderHeaderId);
    copyRows(copyLineVo, lineVo);
    
    // �V�K�����ڐ���
    handleEventInsHdr(exeType, prow, hdrRow);

  } // initializeCopy
  
  /***************************************************************************
   * �R�s�[�����̃`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String chkCopy() throws OAException
  {
    XxpoProvReqtResultVOImpl vo = getXxpoProvReqtResultVO1();
    // �I�����ꂽ���R�[�h���擾
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    // �����I���`�F�b�N���s���܂��B
    chkManyChoice(rows);
    // 1�Ԗڂ̃��R�[�h��I��
    OARow row = (OARow)rows[0];
    // �X�e�[�^�X�`�F�b�N���s���܂��B
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    // �X�e�[�^�X���u���͒��v�A�u���͊����v�A�u��̍ρv�ȊO�̏ꍇ 
    if (!XxpoConstants.PROV_STATUS_NRT.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_NRK.equals(transStatus)
     && !XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus)) 
    {
      throw new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  vo.getName(),
                  row.getKey(),
                  "TransStatus",
                  transStatus,
                  XxcmnConstants.APPL_XXPO, 
                  XxpoConstants.XXPO10145);
          
    }
  
    return (String)row.getAttribute("RequestNo");
  } // chkCopy

  /***************************************************************************
   * �����I���`�F�b�N���s�����\�b�h�ł��B
   * @param rows - �s�I�u�W�F�N�g�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkManyChoice(
    Row[] rows
    ) throws OAException
  {
    // �����I���`�F�b�N���s���܂��B
    if (rows.length != 1)
    {
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10214);
    }
  } // chkManyChoice

  /***************************************************************************
   * ���׍s�R�s�[�������s�����\�b�h�ł��B
   * @param orgVo  - �R�s�[��VO
   * @param destVo - �R�s�[��VO
   ***************************************************************************
   */
  public static void copyRows(OAViewObjectImpl orgVo, OAViewObjectImpl destVo)
  {
    // �ǂ��炩��VO��null�̏ꍇ�͏����I��
    if (orgVo == null || destVo == null)
    {
      return;
    }

    // �R�s�[����VO�̑������擾
    AttributeDef[] attrDefs = orgVo.getAttributeDefs();
    int attrCount = (attrDefs == null) ? 0 : attrDefs.length;
    // �������擾�ł��Ȃ��ꍇ�͏����I��
    if (attrCount == 0)
    {
      return;
    }
    // �R�s�[�p�C�e���[�^���擾���܂��B
    RowSetIterator copyIter = orgVo.findRowSetIterator("copyIter");
    // �R�s�[�p�C�e���[�^��null�̏ꍇ
    if (copyIter == null)
    {
      // �C�e���[�^���쐬���܂��B
      copyIter = orgVo.createRowSetIterator("copyIter");
    }

    boolean rowInserted = false; // �}���t���O
    int lineNum = 1;             // �g�D�ԍ�
    
    // �R�s�[���[�v
    while (copyIter.hasNext())
    {
      // �s���擾
      Row sourceRow = copyIter.next();

      // �s����s�ł��}�������ꍇ
      if (rowInserted)
      {
        // �R�s�[��s�����s�ֈړ����܂��B
        destVo.next();
      }
      // �R�s�[��s���쐬
      Row destRow = destVo.createRow();

      // ������S�ăR�s�[
      for (int i = 0; i < attrCount; i++)
      {
        byte attrKind = attrDefs[i].getAttributeKind();

        if (!(attrKind == AttributeDef.ATTR_ASSOCIATED_ROW ||
              attrKind == AttributeDef.ATTR_ASSOCIATED_ROWITERATOR ||
              attrKind == AttributeDef.ATTR_DYNAMIC))

        {

          String attrName = attrDefs[i].getName();
          if (destVo.lookupAttributeDef(attrName) != null)
          {

            Object attrVal = sourceRow.getAttribute(attrName);

            if (attrVal != null)
            {

              destRow.setAttribute(attrName, attrVal);
            }
          }
        }
      }
      // ���הԍ��F�ő�̖��הԍ�+1���Z�b�g
      destRow.setAttribute("OrderLineNumber", new Number(lineNum++));  
      // �󒍖��׃A�h�I��ID��Null��ݒ�
      destRow.setAttribute("OrderLineId",     null);  
      // �R�s�[�����s�}�����܂��B
      destVo.insertRow(destRow);
      // �}���t���O��true
      rowInserted = true;
    }
    // �R�s�[�p�C�e���[�^���N���[�Y
    copyIter.closeRowSetIterator();
    // �R�s�[��VO�����Z�b�g���܂��B
    destVo.reset();

  } // copyRows

  /***************************************************************************
   * �ύX�Ɋւ���x�����Z�b�g���܂��B
   ***************************************************************************
   */
  public void doWarnAboutChanges()
  {
    // �x���w���쐬�w�b�_VO�擾
    XxpoProvisionInstMakeHeaderVOImpl hdrVo = getXxpoProvisionInstMakeHeaderVO1();
    OARow hdrRow  = (OARow)hdrVo.first();

    // ���Âꂩ�̍��ڂɕύX���������ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("VendorCode"),           hdrRow.getAttribute("DbVendorCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipToCode"),           hdrRow.getAttribute("DbShipToCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipWhseCode"),         hdrRow.getAttribute("DbShipWhseCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          hdrRow.getAttribute("DbShippedDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"),          hdrRow.getAttribute("DbArrivalDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightCarrierCode"),   hdrRow.getAttribute("DbFreightCarrierCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OrderTypeId"),          hdrRow.getAttribute("DbOrderTypeId"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("WeightCapacityClass"),  hdrRow.getAttribute("DbWeightCapacityClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ReqDeptCode"),          hdrRow.getAttribute("DbReqDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("InstDeptCode"),         hdrRow.getAttribute("DbInstDeptCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeFrom"),      hdrRow.getAttribute("DbArrivalTimeFrom"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalTimeTo"),        hdrRow.getAttribute("DbArrivalTimeTo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingMethodCode"),   hdrRow.getAttribute("DbShippingMethodCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightChargeClass"),   hdrRow.getAttribute("DbFreightChargeClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("TakebackClass"),        hdrRow.getAttribute("DbTakebackClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedProdDate"),   hdrRow.getAttribute("DbDesignatedProdDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedItemCode"),   hdrRow.getAttribute("DbDesignatedItemCode"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("DesignatedBranchNo"),   hdrRow.getAttribute("DbDesignatedBranchNo"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),             hdrRow.getAttribute("DbRcvClass"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))) 
    {
      // �ύX�Ɋւ���x����ݒ�
      super.setWarnAboutChanges();  
    } else
    {
      // �x���w���쐬����VO�擾
      XxpoProvisionInstMakeLineVOImpl vo = getXxpoProvisionInstMakeLineVO1();

      /****************************
       * ���׍s�擾
       ****************************/
      Row[] rows = vo.getAllRowsInRange();
      if (rows != null || rows.length > 0) 
      {
        OARow row = null;
        for (int i = 0; i < rows.length; i++)
        {
          // i�Ԗڂ̍s���擾
          row = (OARow)rows[i];

          /******************
           * ���Âꂩ���ύX���ꂽ�ꍇ
           ******************/
          if (!XxcmnUtility.isEquals(row.getAttribute("ItemId"),          row.getAttribute("DbItemId"))
           || !XxcmnUtility.isEquals(row.getAttribute("FutaiCode"),       row.getAttribute("DbFutaiCode"))
           || !XxcmnUtility.isEquals(row.getAttribute("ReqQuantity"),     row.getAttribute("DbReqQuantity"))
           || !XxcmnUtility.isEquals(row.getAttribute("LineDescription"), row.getAttribute("DbLineDescription"))) 
          {
            // �ύX�Ɋւ���x����ݒ�
            super.setWarnAboutChanges();  
            return;
          }
        }
      }
    }
  } // doWarnAboutChanges

// 2009-01-20 v1.12 T.Yoshimoto Add Start
  /***************************************************************************
   * ���Ɏ��ѓ�(�X�V�p)�擾���s�����\�b�h�ł��B
   * @param row - �����Ώۍs
   * @return Date - ���Ɏ��ѓ�(�X�V�p)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public Date getUpdateArrivalDate(
    OARow row
    ) throws OAException
  {

    
    Date scheduleArrivalDate  = null; // ���ɗ\������i�[
    Date shippedDate          = null; // �o�Ɏ��ѓ����i�[
    Date updateArrivalDate       = null; // ���Ɏ��ѓ�(�X�V�p)���i�[
    Number orderHeaderId         = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      
    // ���Ɏ��ѓ����ݒ肳��Ă��邩���m�F(SELECT����)
    Date chkArrivalDate = XxpoUtility.chkArrivalDate(
                            getOADBTransaction(),
                            orderHeaderId);
        
    // ���Ɏ��ѓ��������ꍇ
    if (XxcmnUtility.isBlankOrNull(chkArrivalDate))
    {
      // ���ɗ\������擾
      scheduleArrivalDate = (Date)row.getAttribute("ArrivalDate"); 
      // �o�Ɏ��ѓ����擾
      shippedDate         = (Date)row.getAttribute("ShippedDate");
        
      // �o�Ɏ��ѓ� > ���ɗ\���
      if (XxcmnUtility.chkCompareDate(1, shippedDate, scheduleArrivalDate))
      {
        // ���Ɏ��ѓ��֏o�Ɏ��ѓ���ݒ�
        return shippedDate;

      // ���ɗ\��� > �o�Ɏ��ѓ�
      }else if (XxcmnUtility.chkCompareDate(1, scheduleArrivalDate, shippedDate))
      {
        // ���Ɏ��ѓ��֓��ɗ\�����ݒ�
        return scheduleArrivalDate;

      }
    }

    return chkArrivalDate;
    
  } // getUpdateArrivalDate
// 2009-01-20 v1.12 T.Yoshimoto Add End

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo440001j.server", "XxpoProvisionRequestAMLocal");
  }

  /**
   * 
   * Container's getter for OrderTypeVO1
   */
  public OAViewObjectImpl getOrderTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderTypeVO1");
  }

  /**
   * 
   * Container's getter for NotifStatusVO1
   */
  public OAViewObjectImpl getNotifStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("NotifStatusVO1");
  }

  /**
   * 
   * Container's getter for TransStatusVO1
   */
  public OAViewObjectImpl getTransStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("TransStatusVO1");
  }


  /**
   * 
   * Container's getter for XxpoProvReqtResultVO1
   */
  public XxpoProvReqtResultVOImpl getXxpoProvReqtResultVO1()
  {
    return (XxpoProvReqtResultVOImpl)findViewObject("XxpoProvReqtResultVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRequestPVO1
   */
  public XxpoProvisionRequestPVOImpl getXxpoProvisionRequestPVO1()
  {
    return (XxpoProvisionRequestPVOImpl)findViewObject("XxpoProvisionRequestPVO1");
  }

  /**
   * 
   * Container's getter for WeightCapacityVO1
   */
  public OAViewObjectImpl getWeightCapacityVO1()
  {
    return (OAViewObjectImpl)findViewObject("WeightCapacityVO1");
  }

  /**
   * 
   * Container's getter for TakebackVO1
   */
  public OAViewObjectImpl getTakebackVO1()
  {
    return (OAViewObjectImpl)findViewObject("TakebackVO1");
  }

  /**
   * 
   * Container's getter for FreightVO1
   */
  public OAViewObjectImpl getFreightVO1()
  {
    return (OAViewObjectImpl)findViewObject("FreightVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeHeaderVO1
   */
  public XxpoProvisionInstMakeHeaderVOImpl getXxpoProvisionInstMakeHeaderVO1()
  {
    return (XxpoProvisionInstMakeHeaderVOImpl)findViewObject("XxpoProvisionInstMakeHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeHeaderPVO1
   */
  public XxpoProvisionInstMakeHeaderPVOImpl getXxpoProvisionInstMakeHeaderPVO1()
  {
    return (XxpoProvisionInstMakeHeaderPVOImpl)findViewObject("XxpoProvisionInstMakeHeaderPVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvSearchVO1
   */
  public XxpoProvSearchVOImpl getXxpoProvSearchVO1()
  {
    return (XxpoProvSearchVOImpl)findViewObject("XxpoProvSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeLineVO1
   */
  public XxpoProvisionInstMakeLineVOImpl getXxpoProvisionInstMakeLineVO1()
  {
    return (XxpoProvisionInstMakeLineVOImpl)findViewObject("XxpoProvisionInstMakeLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeLinePVO1
   */
  public XxpoProvisionInstMakeLinePVOImpl getXxpoProvisionInstMakeLinePVO1()
  {
    return (XxpoProvisionInstMakeLinePVOImpl)findViewObject("XxpoProvisionInstMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionInstMakeTotalVO1
   */
  public XxpoProvisionInstMakeTotalVOImpl getXxpoProvisionInstMakeTotalVO1()
  {
    return (XxpoProvisionInstMakeTotalVOImpl)findViewObject("XxpoProvisionInstMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for ShipMethodVO1
   */
  public OAViewObjectImpl getShipMethodVO1()
  {
    return (OAViewObjectImpl)findViewObject("ShipMethodVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvCopyHeaderVO1
   */
  public XxpoProvCopyHeaderVOImpl getXxpoProvCopyHeaderVO1()
  {
    return (XxpoProvCopyHeaderVOImpl)findViewObject("XxpoProvCopyHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvCopyLineVO1
   */
  public XxpoProvCopyLineVOImpl getXxpoProvCopyLineVO1()
  {
    return (XxpoProvCopyLineVOImpl)findViewObject("XxpoProvCopyLineVO1");
  }
}