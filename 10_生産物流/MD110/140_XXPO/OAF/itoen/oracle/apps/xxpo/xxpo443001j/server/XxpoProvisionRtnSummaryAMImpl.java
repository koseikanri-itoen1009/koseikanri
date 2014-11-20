/*============================================================================
* �t�@�C���� : XxpoProvisionRtnSummaryAMImpl
* �T�v����   : �x���ԕi�v��:�����A�v���P�[�V�������W���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  �F�{ �a�Y    �V�K�쐬
* 2008-06-06 1.0  ��r ���    �����ύX�v��#137�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxpo.xxpo443001j.server.XxpoProvisionRtnSumResultVOImpl;

import java.sql.CallableStatement;
import java.sql.SQLException;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �x���ԕi�v��:������ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnSummaryAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnSummaryAMImpl()
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
    //�x���ԕi�v�񌟍�VO
    OAViewObject vo = getXxpoProvSearchVO1();

    //1�s���Ȃ��ꍇ�A��s�쐬
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);

      // �v���t�@�C�������\���i�\ID�擾
      String repPriceListId = XxcmnUtility.getProfileValue(
                                getOADBTransaction(),
                                XxpoConstants.REP_PRICE_LIST_ID);
      // ��\���i�\ID���擾�ł��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(repPriceListId)) 
      {
        throw new OAException(XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10113);
      }
      row.setAttribute("RepPriceListId", repPriceListId);
    }
  } //initializeList
  
  /***************************************************************************
   * �x���ԕi�v���ʂ̌����������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void doSearchList() throws OAException
    {
      //�x���ԕi����VO�擾
      XxpoProvSearchVOImpl svo = getXxpoProvSearchVO1();

      //���������ݒ�
      OARow shRow = (OARow)svo.first();
      HashMap shParams = new HashMap();

      shParams.put("orderType", shRow.getAttribute("OrderType"));
      shParams.put("vendorCode", shRow.getAttribute("VendorCode"));
      shParams.put("shipToCode", shRow.getAttribute("ShipToCode"));
      shParams.put("reqNo", shRow.getAttribute("ReqNo"));
      shParams.put("shipToNo", shRow.getAttribute("ShipToNo"));
      shParams.put("transStatus", shRow.getAttribute("TransStatusCode"));
      shParams.put("notifStatus", shRow.getAttribute("NotifStatusCode"));
      shParams.put("shipDateFrom", shRow.getAttribute("ShipDateFrom"));
      shParams.put("shipDateTo", shRow.getAttribute("ShipDateTo"));
      shParams.put("arvlDateFrom", shRow.getAttribute("ArvlDateFrom"));
      shParams.put("arvlDateTo", shRow.getAttribute("ArvlDateTo"));
      shParams.put("reqDeptCode", shRow.getAttribute("ReqDeptCode"));
      shParams.put("instDeptCode", shRow.getAttribute("InstDeptCode"));
      shParams.put("shipWhseCode", shRow.getAttribute("ShipWhseCode"));
      shParams.put("exeType", shRow.getAttribute("ExeType"));
      //�x���ԕi����VO�擾
      XxpoProvisionRtnSumResultVOImpl vo = getXxpoProvisionRtnSumResultVO1();

      //�������s
      vo.initQuery(shParams);

    } //doSearchList

  /***************************************************************************
   * �x���w���쐬�w�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param reqNo   - �˗�No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
    // �x���ԕi�v�񌟍�VO
    OAViewObject svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0) 
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey", new Number(1));
      srow.setAttribute("ExeType", exeType);
      // �v���t�@�C�������\���i�\ID���擾
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

    // �x���ԕi�쐬�w�b�_PVO
    XxpoProvisionRtnMakeHeaderPVOImpl pvo = getXxpoProvisionRtnMakeHeaderPVO1();
    OARow prow = null;
    // 1�s���Ȃ��ꍇ�͋�s�쐬    
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

    OARow row = null;
    // �V�K�̏ꍇ
    if (XxcmnUtility.isBlankOrNull(reqNo)) 
    {
      // �x���ԕi�쐬�w�b�_VO�擾
      XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();
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
      row.setAttribute("NewFlag", XxcmnConstants.STRING_Y); // �V�K�t���O
      row.setAttribute("TransStatus", XxpoConstants.PROV_STATUS_NRT); //�X�e�[�^�X(���͒�)
      row.setAttribute("NewModifyFlg", XxpoConstants.NEW_MODIFY_FLG_OFF); // �C���t���O(OFF)
      row.setAttribute("RcvClass", XxpoConstants.RCV_CLASS_OFF); // �w�����(OFF)
      row.setAttribute("FixClass", XxpoConstants.FIX_CLASS_OFF); // ���z�m��(OFF)
      // �V�K�����ڐ���
      handleEventInsHdr(exeType, prow, row);

    // �X�V�̏ꍇ
    } else
    {
      // �˗�No�Ō��������s
      doSearchHdr(reqNo);
      // �x���ԕi�쐬�w�b�_VO�擾
      XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();
      row = (OARow)vo.first();
      // �X�V�����ڐ���
      handleEventUpdHdr(exeType, prow, row);
    }
    // ���׍s�̌���
    doSearchLine(exeType);
  } // initializeHdr
  /***************************************************************************
   * �x���ԕi�쐬�w�b�_��ʂ̌����������s�����\�b�h�ł��B
   * @param  reqNo - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
  ) throws OAException
  {
    // �x���ԕi�쐬�w�b�_VO�擾
    XxpoProvisionRtnMakeHeaderVOImpl vo = getXxpoProvisionRtnMakeHeaderVO1();

    // ���������s���܂��B
    vo.initQuery(reqNo);
    vo.first();

    // �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((vo == null) || (vo.getFetchedRowCount() == 0))
    {
      // �x���w���쐬PVO
      XxpoProvisionRtnMakeHeaderPVOImpl pvo = getXxpoProvisionRtnMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10500);
    }
  } // doSearchHdr

  /***************************************************************************
   * �x���w���쐬���׉�ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeLine(
    String exeType
  )
  {
    // �x���ԕi�쐬�w�b�_VO�擾
    OAViewObject hdrVvo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // �V�K�t���O

    // �x���ԕi�쐬����PVO
    XxpoProvisionRtnMakeLinePVOImpl pvo = getXxpoProvisionRtnMakeLinePVO1();    
    // 1�s���Ȃ��ꍇ�A��s�쐬
    OARow prow = null;
    if (pvo.getFetchedRowCount() == 0) 
    {
      pvo.setMaxFetchSize(0);
      pvo.insertRow(pvo.createRow());
      prow = (OARow)pvo.first();
      prow.setNewRowState(OARow.STATUS_INITIALIZED);
      prow.setAttribute("RowKey", new Number(1));
      // PVO�����ݒ�
      handleEventAllOnLine(prow);
    } else 
    {
      prow = (OARow)pvo.first();
    }

    // �V�K�t���O���uN:�X�V�v�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      handleEventUpdLine(exeType,
                         prow,
                         hdrRow);
    }
  } // initializeLine

  /***************************************************************************
   * �x���ԕi�쐬���׉�ʂ̌����������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchLine(
    String exeType
  ) throws OAException
  {
    // �x���ԕi�쐬�w�b�_VO�擾
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �󒍃w�b�_�A�h�I��ID���擾���܂��B
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");  // �󒍃w�b�_�A�h�I��ID
    // �x���ԕi�쐬����VO�擾
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    // ���������s���܂��B
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // 1�s�����݂��Ȃ��ꍇ�A1�s�쐬
    if (vo.getFetchedRowCount() == 0) 
    {
      addRow(exeType);
    }
    // �x���ԕi�쐬���vVO�擾
    XxpoProvisionRtnMakeTotalVOImpl totalVo = getXxpoProvisionRtnMakeTotalVO1();
    // ���������s���܂��B
    totalVo.initQuery(orderHeaderId);
  } // doSearchLine

  /***************************************************************************
   * �s�}���������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void addRow(
    String exeType
  ) throws OAException
  {
    // ������
    OARow maxRow = null;
    Number maxOrderLineNumber = new Number(0);
    // �x���ԕi�쐬�w�b�_VO�擾
    OAViewObject hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �󒍃w�b�_�A�h�I��ID�擾
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
    // �x���ԕi�쐬����VO�擾
    OAViewObject vo = getXxpoProvisionRtnMakeLineVO1();
    // �ő喾�הԍ��擾
    maxRow = (OARow)vo.last();
    // ���R�[�h�����݂���ꍇ
    if (maxRow != null) 
    {
      maxOrderLineNumber = (Number)maxRow.getAttribute("OrderLineNumber");
    }
    // ����VO�ɑ}������s���쐬
    OARow row = (OARow)vo.createRow();
    // Switcher�̐���
    row.setAttribute("ItemSwitcher", "ItemNo");  // �i��
    row.setAttribute("FutaiSwitcher", "FutaiCode");  // �t��
    row.setAttribute("ReqSwitcher", "ReqQuantity"); // �˗�����
    row.setAttribute("PriceSwitcher", "UnitPrice"); // �P��
    row.setAttribute("DescSwitcher", "LineDescription"); // ���l
    row.setAttribute("ShippedSwitcher", "ShippedIconDisable"); // �o�Ɏ��уA�C�R��
    row.setAttribute("ShipToSwitcher", "ShipToIconDisable");  // ���Ɏ��уA�C�R��
    row.setAttribute("ReserveSwitcher", "ReserveIconDisable");  // �����A�C�R��
    row.setAttribute("DeleteSwitcher" , "DeleteEnable");  // �폜�A�C�R��
    // �f�t�H���g�l�̐ݒ�
    row.setAttribute("RecordType"     , XxcmnConstants.STRING_Y); // �V�K�s
    row.setAttribute("FutaiCode"      , XxcmnConstants.STRING_ZERO);  // �t��
    row.setAttribute("OrderLineNumber", maxOrderLineNumber.add(1)); // �s�ԍ�
    row.setAttribute("OrderHeaderId"  , orderHeaderId); // �󒍃w�b�_�A�h�I��ID
    // �쐬�����s�̑}��
    vo.last();
    vo.next();
    vo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);
  } // AddRow

  /*****************************************************************************
   * �w�肳�ꂽ�s���폜���܂��B
   * @param exeType - �N���^�C�v
   * @param orderLineNumber - ���הԍ�
   ****************************************************************************/
  public void doDeleteLine(
    String exeType,
    String orderLineNumber
  ) 
  {
    // �x���ԕi�쐬�w�b�_VO�擾
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String reqNo = (String)hdrRow.getAttribute("RequestNo");  // �˗�No
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // �V�K�t���O
    // �x���ԕi�쐬����VO�擾
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    // �폜�Ώۍs���擾
    OARow row = (OARow)vo.getFirstFilteredRow("OrderLineNumber", new Number(Integer.parseInt(orderLineNumber)));
    // �󒍖��׃A�h�I��ID���擾
    Number orderLineId = (Number)row.getAttribute("OrderLineId");

    Row[] rows = null;
    rows = vo.getAllRowsInRange();
    // �X�V�s�̖��ׂ�1�������Ȃ��ꍇ
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
    if ((row != null)
      && (XxcmnUtility.isBlankOrNull(orderLineId))) 
    {
      // �}���s�폜
      row.remove();
      // �폜�����������b�Z�[�W��\��
      putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);

    // �X�V�s�̏ꍇ
    } else 
    {
      // �폜�`�F�b�N����
      chkOrderLineDel(vo, hdrRow, row);
      // �r���`�F�b�N
      chkLockAndExclusive(hdrVo, hdrRow);
      // �폜����
      XxpoUtility.deleteOrderLine(getOADBTransaction(), orderLineId);
      // �󒍃w�b�_�A�h�I��ID���擾
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
      // ���ׂ̍��v�l�擾
      HashMap retParams = XxpoUtility.getSummaryDataOrderLine(
                            getOADBTransaction(),
                            orderHeaderId);
      hdrRow.setAttribute("SumQuantity", retParams.get("sumQuantity")); // ���v����
      hdrRow.setAttribute("SumWeight", retParams.get("sumWeight"));     // �ύڏd�ʍ��v
      hdrRow.setAttribute("SumCapacity", retParams.get("sumCapacity")); // �ύڗe�ύ��v
      String sumQuantity = (String)retParams.get("sumQuantity");
      String sumWeight = (String)retParams.get("sumWeight");
      String sumCapacity = (String)retParams.get("sumCapacity");
      // �w�b�_�X�V����
      XxpoUtility.updateSummaryInfo(getOADBTransaction(),
                                    orderHeaderId,
                                    sumQuantity,
                                    null,
                                    null,
                                    sumWeight,
                                    sumCapacity);
      // �R�~�b�g���� 
      doCommit(reqNo);
      // �폜�����������b�Z�[�W��\��
      putSuccessMessage(XxpoConstants.TOKEN_NAME_DEL);
    }
  } // doDeleteLine

  /***************************************************************************
   * �x���ԕi�v���ʂ̋��z�m�菈�����s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void doAmountFixList() throws OAException
    {
      ArrayList exceptions = new ArrayList(100);
      boolean exeFlag = false;

      //�����Ώۂ��擾
      OAViewObject vo = getXxpoProvisionRtnSumResultVO1();
      Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

      //���I���`�F�b�N
      if ((rows == null) || (rows.length == 0))
      {
        //�G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10144
        );
      } else 
      {
        OARow row = null;
        //���i�ݒ�`�F�b�Nloop
        for (int i = 0; i < rows.length; i++) 
        {
          //i�Ԗڂ̍s���擾
          row = (OARow)rows[i];
          //���z�m��O�`�F�b�N
          chkAmountFix(vo, row, exceptions);
        }
        //�G���[���������ꍇ�A��O���X���[���܂��B
        if (exceptions.size() > 0) 
        {
          OAException.raiseBundledOAException(exceptions);
        }
        //�X�V����loop
        for (int i = 0; i < rows.length; i++) 
        {
          //i�Ԗڂ̍s���擾
          row = (OARow)rows[i];
          Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); //�󒍃w�b�_�A�h�I��ID

          //�r���`�F�b�N&���b�N
          chkLockAndExclusive(vo, row);

          //���i�m�菈�����s
          XxpoUtility.updateFixClass(
            getOADBTransaction(),
            orderHeaderId,
            XxpoConstants.FIX_CLASS_ON
          );
          exeFlag = true;
        }

        if (exeFlag) 
        {
          //�R�~�b�g���s
          doCommitList();
        }
      }
    } //doAmountFixList

  /***************************************************************************
   * �x���w���w�b�_��ʂ̃R�~�b�g�E�Č����������s�����\�b�h�ł��B
   * @param reqNo - �˗�No
   ***************************************************************************
   */
  public void doCommit(
    String reqNo
  ) 
  {
    // �R�~�b�g���s
    XxpoUtility.commit(getOADBTransaction());
    // �w�b�_�̍Č������s���܂�
    doSearchHdr(reqNo);
    // �x���˗��v�񌟍�VO
    OAViewObject vo = getXxpoProvSearchVO1();
    OARow row = (OARow)vo.first();
    String exeType = (String)row.getAttribute("ExeType");
    // ���ׂ̍Č������s���܂�
    doSearchLine(exeType);
  } // doCommit

  /***************************************************************************
   * �x���w���v���ʂ̃R�~�b�g�E�Č����������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void doCommitList() throws OAException
    {
      //�R�~�b�g���s
      XxpoUtility.commit(getOADBTransaction());
      //�Č������s���܂��B
      doSearchList();
      //�X�V�������b�Z�[�W
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30042,
        null,
        OAException.INFORMATION,
        null
      );
    } //doCommitList

  /***************************************************************************
   * �x���ԕi�쐬�w�b�_��ʂ̎x������������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void doProvCancel() throws OAException
    {
      ArrayList exceptions = new ArrayList(100);
      boolean exeFlag = false;

      // �x���ԕi�쐬�w�b�_VO�擾
      OAViewObject vo = getXxpoProvisionRtnMakeHeaderVO1();
      OARow row = (OARow)vo.first();

      // �G���[���������ꍇ�̓G���[���X���[���܂��B
      if (exceptions.size() > 0) 
      {
        OAException.raiseBundledOAException(exceptions);
      }

      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
      String requestNo = (String)row.getAttribute("RequestNo"); // �˗�No

      // �r���`�F�b�N
      chkLockAndExclusive(vo, row);

      // �X�e�[�^�X���u����v�ɍX�V���܂��B
      XxpoUtility.updateTransStatus(
        getOADBTransaction(),
        orderHeaderId,
        XxpoConstants.PROV_STATUS_CAN
      );

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
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // �x���ԕi�쐬�w�b�_VO�擾
    OAViewObject vo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow row = (OARow)vo.first();

    // ���փ`�F�b�N
    chkNext(vo, row, exceptions);
    // �G���[���������ꍇ�̓G���[���X���[���܂��B
    if (exceptions.size() > 0) 
    {
      OAException.raiseBundledOAException(exceptions);
    }

    Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    String requestNo = (String)row.getAttribute("RequestNo"); // �˗�No
  } // doNext

  /***************************************************************************
   * �˗������w�����փR�s�[���郁�\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCopyReqQty() throws OAException 
  {
    // �x���ԕi�쐬���׏��VO�擾
    OAViewObject vo = getXxpoProvisionRtnMakeLineVO1();
    Row[] rows= vo.getAllRowsInRange();
    if ((rows != null) || (rows.length > 0)) 
    {
      OARow row = null;
      String reqQty = null;
      String dbReqQty = null;
      for (int i = 0; i < rows.length; i++) 
      {
        row = (OARow)rows[i];
        reqQty = (String)row.getAttribute("ReqQuantity"); // �˗���(���)
        dbReqQty = (String)row.getAttribute("DbReqQuantity"); // �˗���(DB)
        // �˗������ύX���ꂽ�ꍇ�A�w�����փR�s�[
        if (!XxcmnUtility.chkCompareNumeric(3, reqQty, dbReqQty)) 
        {
          row.setAttribute("InstQuantity", reqQty);
        }
      }
    }
  } // doCopyReqQty

  /***************************************************************************
   * �x���ԕi���׉�ʂ̓K�p�������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   * @return  HashMap - �߂�l�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
  ) throws OAException 
  {
    boolean exeFlag = false;  // ���s�t���O

    // �`�F�b�N����
    chkOrderLine(exeType);

    // �x���ԕi�쐬�w�b�_VO�擾
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");  // �V�K�t���O
    String reqNo = (String)hdrRow.getAttribute("RequestNo");   // �˗�No
    String tokenName = null;

    // �V�K�t���O���uN:�X�V�v�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // �r���`�F�b�N
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;
    // �V�K�t���O���uY:�V�K�v�̏ꍇ
    } else 
    {
      // �˗�No���擾      
      reqNo = XxcmnUtility.getSeqNo(getOADBTransaction(), "�˗�No");
      hdrRow.setAttribute("RequestNo", reqNo);

      // �󒍃w�b�_�A�h�I��ID���擾
      Number orderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());
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
      tokenName = null;
    }

    HashMap retParams = new HashMap();
    retParams.put("tokenName", tokenName);
    retParams.put("reqNo", reqNo);
    return retParams;
  } // doApply

  /***************************************************************************
   * �}���E�X�V�������s�����\�b�h�ł��B
   * @return boolean - True:�w�b�_�܂��͖��ׂ��X�V�B False:�w�b�_�A���׍X�V�����B
   * @param newFlag - �V�K�t���O Y:�V�K�AN:�X�V
   * @param hdrRow  - �w�b�_�s�I�u�W�F�N�g
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean doExecute(
    String newFlag,
    OARow hdrRow,
    String exeType
  ) throws OAException
  {
    // �x���ԕi����VO
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();
    boolean sumQtyFlag = false; // ���v���ʕύX�t���O
    boolean lineExeFlag = false;  // ���׎��s�t���O
    boolean hdrExeFlag = false; // �w�b�_���s�t���O
    // ���׍X�V�s�擾
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        updRow = (OARow)updRows[i];
        // �i��ID�A�t�уR�[�h�A�˗����A�P���A���l���ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(updRow.getAttribute("ItemId"),updRow.getAttribute("DbItemId")) 
         || !XxcmnUtility.isEquals(updRow.getAttribute("FutaiCode"),updRow.getAttribute("DbFutaiCode"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("ReqQuantity"),updRow.getAttribute("DbReqQuantity"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("UnitPriceNum"),updRow.getAttribute("DbUnitPriceNum"))
         || !XxcmnUtility.isEquals(updRow.getAttribute("LineDescription"),updRow.getAttribute("DbLineDescription"))
        )
        {
          // �X�V����
          updateOrderLine(updRow);
          // ���׎��s�t���O��True�ɕύX
          lineExeFlag = true;
        }

        // �w�������ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(
               XxcmnUtility.commaRemoval((String)updRow.getAttribute("InstQuantity")),
               XxcmnUtility.commaRemoval((String)updRow.getAttribute("DbInstQuantity"))
               )
            )
        {
          // ���v���ʕύX�t���O��true�ɕύX
          sumQtyFlag = true;
        }
      }
    }

    // ���גǉ��s�擾
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0)) 
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        insRow = (OARow)insRows[i];

        // �S�ău�����N�̍s�͖�������
        if (!XxcmnUtility.isBlankOrNull(insRow.getAttribute("ItemNo"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("FutaiCode"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("ReqQuantity"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("UnitPrice"))
         || !XxcmnUtility.isBlankOrNull(insRow.getAttribute("LineDescription"))
        ) 
        {
          // �}������
          insertOrderLine(hdrRow, insRow);
          // ���׎��s�t���O��true�ɕύX
          lineExeFlag = true;
          // ���v���ʕύX�t���O��true�ɕύX
          sumQtyFlag = true;
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

    // ���ׂ����s����Ă����ꍇ
    if (lineExeFlag) 
    {
      // �󒍃w�b�_�A�h�I��ID���擾
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId");
      // ���ׂ̍��v�l�擾
      HashMap retParams = XxpoUtility.getSummaryDataOrderLine(
                            getOADBTransaction(),
                            orderHeaderId);
      hdrRow.setAttribute("SumQuantity", retParams.get("sumQuantity")); // ���v����
      hdrRow.setAttribute("SumWeight", retParams.get("sumWeight"));     // �ύڏd�ʍ��v
      hdrRow.setAttribute("SumCapacity", retParams.get("sumCapacity")); // �ύڗe�ύ��v
    }
    // �w�b�_�V�K�ǉ��̏ꍇ
    if (XxcmnConstants.STRING_Y.equals(newFlag)) 
    {
      // �}������
      insertOrderHdr(hdrRow);
      // �w�b�_���s�t���O��true�ɕύX
      hdrExeFlag = true;

    // �w�b�_�X�V�̏ꍇ
    } else 
    {
      // �ȉ����X�V���ꂽ�ꍇ
      // �E�����敪 �E�d�ʗe�ϋ敪 �E�˗�����    �E�w������ �E�����
      // �E�z����   �E�o�ɑq��    �E�^���Ǝ�    �E�o�ɓ�   �E���ɓ�
      // �E���׎���(From)        �E���׎���(To)�E�z���敪 �E�^���敪
      // �E����敪 �E������      �E�����i��    �E�����ԍ� �E�E�v
      // �E�w����� �E���z�m��    �E���v���ʕύX�t���OsumQtyFlag
      if (!XxcmnUtility.isEquals(hdrRow.getAttribute("OrderTypeId"),          hdrRow.getAttribute("DbOrderTypeId"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("WeightCapacityClass"),  hdrRow.getAttribute("DbWeightCapacityClass"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ReqDeptCode"),          hdrRow.getAttribute("DbReqDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("InstDeptCode"),         hdrRow.getAttribute("DbInstDeptCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("VendorCode"),           hdrRow.getAttribute("DbVendorCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipToCode"),           hdrRow.getAttribute("DbShipToCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShipWhseCode"),         hdrRow.getAttribute("DbShipWhseCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FreightCarrierCode"),   hdrRow.getAttribute("DbFreightCarrierCode"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          hdrRow.getAttribute("DbShippedDate"))
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"),          hdrRow.getAttribute("DbArrivalDate"))
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
       || !XxcmnUtility.isEquals(hdrRow.getAttribute("FixClass"),             hdrRow.getAttribute("DbFixClass"))
       || sumQtyFlag)
       {
          // �X�V����
          updateOrderHdr(hdrRow);
          // �w�b�_���s�t���O��true�ɕύX
          hdrExeFlag = true;
       }
    }
    // �w�b�_�A���ׂ̂����ꂩ���o�^�E�X�V���ꂽ�ꍇtrue��Ԃ�
    if (hdrExeFlag || lineExeFlag) 
    {
      return true;
    } else 
    {
      return false;
    }
  } // doExecute

  /*****************************************************************************
   * �󒍖��׃A�h�I���̃f�[�^���X�V���܂��B
   * @param updRow - �X�V�Ώۍs
   * @throws OAException - OA��O
   ****************************************************************************/
  public void updateOrderLine(
    OARow updRow
  ) throws OAException
  {
    String apiName = "updateOrderLine";

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.shipping_inventory_item_id = :1 ");  // �o�וi��ID
    sb.append("        ,xola.shipping_item_code         = :2 ");  // �o�וi��
    sb.append("        ,xola.quantity                   = TO_NUMBER(:3) ");  // ����
    sb.append("        ,xola.uom_code                   = :4 ");  // �P��
    sb.append("        ,xola.based_request_quantity     = TO_NUMBER(:5) ");  // ���_�˗�����
    sb.append("        ,xola.request_item_id            = :6 ");  // �˗��i��ID
    sb.append("        ,xola.request_item_code          = :7 ");  // �˗��i��
    sb.append("        ,xola.futai_code                 = :8 ");  // �t�уR�[�h
    sb.append("        ,xola.line_description           = :9 ");  // �E�v
    sb.append("        ,xola.unit_price                 = TO_NUMBER(:10) "); // �P��
    sb.append("        ,xola.weight                     = TO_NUMBER(:11) "); // �d��
    sb.append("        ,xola.capacity                   = TO_NUMBER(:12) "); // �e��
    sb.append("        ,xola.last_updated_by            = FND_GLOBAL.USER_ID ");  // �ŏI�X�V��
    sb.append("        ,xola.last_update_date           = SYSDATE ");             // �ŏI�X�V��
    sb.append("        ,xola.last_update_login          = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xola.order_line_id = :13 ; ");             // �󒍖��׃A�h�I��ID
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                getOADBTransaction().DEFAULT);
    try 
    {
      // �����擾
      Number invItemId        = (Number)updRow.getAttribute("InvItemId");       // �o�וi��ID
      String itemNo           = (String)updRow.getAttribute("ItemNo");          // �o�וi��
      String instQuantity     = (String)updRow.getAttribute("InstQuantity");    // ����
      String itemUm           = (String)updRow.getAttribute("ItemUm");          // �P��
      String reqQuantity      = (String)updRow.getAttribute("ReqQuantity");     // ���_�˗�����
      Number whseInvItemId    = (Number)updRow.getAttribute("WhseInvItemId");   // �˗��i��ID
      String whseItemNo       = (String)updRow.getAttribute("WhseItemNo");      // �˗��i��
      String futaiCode        = (String)updRow.getAttribute("FutaiCode");       // �t�уR�[�h
      String lineDescription  = (String)updRow.getAttribute("LineDescription"); // �E�v
      String unitPrice        = XxcmnUtility.stringValue(
                                  (Number)updRow.getAttribute("UnitPriceNum")); // �P��
      String weight           = (String)updRow.getAttribute("Weight");          // �d��
      String capacity         = (String)updRow.getAttribute("Capacity");        // �e��
      Number orderLineId      = (Number)updRow.getAttribute("OrderLineId");     // �󒍖��׃A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));
      cstmt.setString(i++, itemNo);
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity));
      cstmt.setString(i++, itemUm);
      cstmt.setString(i++, reqQuantity);
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));
      cstmt.setString(i++, whseItemNo);
      cstmt.setString(i++, futaiCode);
      cstmt.setString(i++, lineDescription);
      cstmt.setString(i++, unitPrice);
      cstmt.setString(i++, weight);
      cstmt.setString(i++, capacity);
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s) 
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                             XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine

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
    String apiName = "insertOrderLine";    

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_line  xxwsh_order_lines_all%ROWTYPE; ");
    sb.append("  ln_line_id NUMBER; ");
    sb.append("BEGIN ");
    sb.append("  SELECT xxwsh_order_lines_all_s1.NEXTVAL INTO ln_line_id FROM DUAL; ");
    sb.append("  lr_line.order_line_id               := ln_line_id; ");
    sb.append("  lr_line.order_header_id             := :1; ");
    sb.append("  lr_line.order_line_number           := :2; ");
    sb.append("  lr_line.request_no                  := :3; ");
    sb.append("  lr_line.shipping_inventory_item_id  := :4; ");
    sb.append("  lr_line.shipping_item_code          := :5; ");
    sb.append("  lr_line.quantity                    := TO_NUMBER(:6); ");
    sb.append("  lr_line.uom_code                    := :7; ");
    sb.append("  lr_line.based_request_quantity      := TO_NUMBER(:8); ");
    sb.append("  lr_line.request_item_id             := :9; ");
    sb.append("  lr_line.request_item_code           := :10; ");
    sb.append("  lr_line.futai_code                  := :11; ");
    sb.append("  lr_line.delete_flag                 := 'N'; ");
    sb.append("  lr_line.line_description            := :12; ");
    sb.append("  lr_line.unit_price                  := :13; ");
    sb.append("  lr_line.weight                      := TO_NUMBER(:14); ");
    sb.append("  lr_line.capacity                    := TO_NUMBER(:15); ");
    sb.append("  lr_line.created_by                  := FND_GLOBAL.USER_ID; ");
    sb.append("  lr_line.creation_date               := SYSDATE; ");
    sb.append("  lr_line.last_updated_by             := FND_GLOBAL.USER_ID; ");
    sb.append("  lr_line.last_update_date            := SYSDATE; ");
    sb.append("  lr_line.last_update_login           := FND_GLOBAL.LOGIN_ID; ");
    sb.append("  INSERT INTO xxwsh_order_lines_all VALUES lr_line; ");
    sb.append("END; ");
    // PL/SQL�̐ݒ���s���܂��B
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
      String unitPrice       = XxcmnUtility.stringValue((Number)insRow.getAttribute("UnitPriceNum"));    // �P��
      String weight          = (String)insRow.getAttribute("Weight");          // �d��
      String capacity        = (String)insRow.getAttribute("Capacity");        // �e��

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineNumber));  // ���הԍ�
      cstmt.setString(i++, requestNo);                            // �˗�No
      cstmt.setInt(i++, XxcmnUtility.intValue(invItemId));        // �o�וi��ID
      cstmt.setString(i++, itemNo);                               // �o�וi��
      cstmt.setString(i++, XxcmnUtility.commaRemoval(instQuantity)); // ����
      cstmt.setString(i++, itemUm);                               // �P��
      cstmt.setString(i++, reqQuantity);                          // ���_�˗�����
      cstmt.setInt(i++, XxcmnUtility.intValue(whseInvItemId));    // �˗��i��ID
      cstmt.setString(i++, whseItemNo);                           // �˗��i��
      cstmt.setString(i++, futaiCode);                            // �t�уR�[�h
      cstmt.setString(i++, lineDescription);                      // �E�v
      cstmt.setString(i++, unitPrice);                            // �P��
      cstmt.setString(i++, weight);                               // �d��
      cstmt.setString(i++, capacity);                             // �e��

      // PL/SQL���s
      cstmt.execute();

    } catch(SQLException s) 
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void insertOrderHdr(
    OARow hdrRow
  ) throws OAException
  {
    String apiName = "insertOrderHdr";

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  lr_hdr  xxwsh_order_headers_all%ROWTYPE; ");
    sb.append("BEGIN ");
    sb.append("  lr_hdr.order_header_id               := :1; ");  // �󒍃w�b�_�A�h�I��ID
    sb.append("  lr_hdr.order_type_id                 := :2; ");  // �󒍃^�C�vID
    sb.append("  lr_hdr.organization_id               := FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'); ");  // �g�DID
    sb.append("  lr_hdr.latest_external_flag          := 'Y'; "); // �ŐV�t���O
    sb.append("  lr_hdr.ordered_date                  := SYSDATE; "); // �󒍓�
    sb.append("  lr_hdr.customer_id                   := :3; ");  // �ڋqID
    sb.append("  lr_hdr.customer_code                 := :4; ");  // �ڋq
    sb.append("  lr_hdr.shipping_instructions         := :5; ");  // �o�׎w��
    sb.append("  lr_hdr.request_no                    := :6; ");  // �˗�No
    sb.append("  lr_hdr.req_status                    := '05'; ");  // �X�e�[�^�X
    sb.append("  lr_hdr.schedule_ship_date            := :7; "); // �o�ח\���
    sb.append("  lr_hdr.schedule_arrival_date         := :8; "); // ���ח\���
    sb.append("  lr_hdr.freight_charge_class          := :9; "); // �^���敪
    sb.append("  lr_hdr.amount_fix_class              := :10; "); // �L�����z�m��敪
    sb.append("  lr_hdr.deliver_from_id               := :11; "); // �o�׌�ID
    sb.append("  lr_hdr.deliver_from                  := :12; "); // �o�׌��ۊǏꏊ
    sb.append("  lr_hdr.prod_class                    := FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY'); ");  // ���i�敪
    sb.append("  lr_hdr.sum_quantity                  := TO_NUMBER(:13); "); // ���v����
    sb.append("  lr_hdr.sum_weight                    := TO_NUMBER(:14); "); // �ύڏd�ʍ��v
    sb.append("  lr_hdr.sum_capacity                  := TO_NUMBER(:15); "); // �ύڗe�ύ��v
    sb.append("  lr_hdr.actual_confirm_class          := 'N'; "); // ���ьv��ϋ敪
    sb.append("  lr_hdr.performance_management_dept   := :16; "); // ���ъǗ�����
    sb.append("  lr_hdr.instruction_dept              := :17; "); // �w������
    sb.append("  lr_hdr.vendor_id                     := :18; "); // �����ID
    sb.append("  lr_hdr.vendor_code                   := :19; "); // �����
    sb.append("  lr_hdr.vendor_site_id                := :20; "); // �����T�C�gID
    sb.append("  lr_hdr.vendor_site_code              := :21; "); // �����T�C�g
    sb.append("  lr_hdr.shipped_date                  := :22; "); // �o�ד�
    sb.append("  lr_hdr.arrival_date                  := :23; "); // ���ד�
    sb.append("  lr_hdr.created_by                    := FND_GLOBAL.USER_ID; ");  // �쐬��
    sb.append("  lr_hdr.creation_date                 := SYSDATE; "); // �쐬��
    sb.append("  lr_hdr.last_updated_by               := FND_GLOBAL.USER_ID; ");  // �ŏI�X�V��
    sb.append("  lr_hdr.last_update_date              := SYSDATE; "); // �ŏI�X�V��
    sb.append("  lr_hdr.last_update_login             := FND_GLOBAL.LOGIN_ID; ");  // �ŏI�X�V���O�C��
    sb.append("  INSERT INTO xxwsh_order_headers_all VALUES lr_hdr; ");
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
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
      String requestNo           = (String)hdrRow.getAttribute("RequestNo");             // �˗�No
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // �o�ɗ\���(=�o�ɓ�)
      String freightChargeClass  = (String)hdrRow.getAttribute("FreightChargeClass");    // �^���敪
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // ���z�m��
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // �o�ɑq��ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // �o�ɑq��
      String sumQuantity         = XxcmnUtility.stringValue((Number)hdrRow.getAttribute("SumQuantity")); // ���v����
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // �ύڏd�ʍ��v
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // �ύڗe�ύ��v
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // �˗�����
      String instDeptCode        = (String)hdrRow.getAttribute("ReqDeptCode");           // �w������(=�˗�����)
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // �����ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // �����
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // �z����ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // �z����

      int i = 1;
      // �p�����[�^�ݒ�
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // �����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // �ڋqID
      cstmt.setString(i++, customerCode);                         // �ڋq
      cstmt.setString(i++, instructions);                         // �E�v
      cstmt.setString(i++, requestNo);                            // �˗�No
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // �o�ɗ\���
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // ���ɗ\���
      cstmt.setString(i++, XxcmnConstants.OBJECT_OFF);            // �^���敪
      cstmt.setString(i++, fixClass);                             // ���z�m��
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // �o�ɑq��ID
      cstmt.setString(i++, shipWhseCode);                         // �o�ɑq��
      cstmt.setString(i++, sumQuantity);                          // ���v����
      cstmt.setString(i++, sumWeight);                            // �ύڏd�ʍ��v
      cstmt.setString(i++, sumCapacity);                          // �ύڗe�ύ��v
      cstmt.setString(i++, reqDeptCode);                          // �˗�����
      cstmt.setString(i++, instDeptCode);                         // �w������
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // �����ID
      cstmt.setString(i++, vendorCode);                           // �����
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // �z����ID
      cstmt.setString(i++, shipToCode);                           // �z����
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // �o�ɓ�
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // ���ɓ�

      // PL/SQL���s
      cstmt.execute();
      
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s) 
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        // �������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s) 
      {
        // ���[���o�b�N
          XxpoUtility.rollBack(getOADBTransaction());
          XxcmnUtility.writeLog(getOADBTransaction(),
                                XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
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
    String apiName = "updateOrderHdr";

    // PL/SQL�̍쐬���s���܂��B
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.order_type_id         = :1 " ); // �󒍃^�C�vID
    sb.append("       ,xoha.customer_id           = :2 " ); // �ڋqID
    sb.append("       ,xoha.customer_code         = :3 " ); // �ڋq
    sb.append("       ,xoha.shipping_instructions = :4 " ); // �o�׎w��
    sb.append("       ,xoha.schedule_ship_date    = :5 "); // �o�ח\���
    sb.append("       ,xoha.schedule_arrival_date = :6 "); // ���ח\���
    sb.append("       ,xoha.amount_fix_class      = :7 " ); // �L�����z�m��敪
    sb.append("       ,xoha.deliver_from_id       = :8 " ); // �o�׌�ID
    sb.append("       ,xoha.deliver_from          = :9 " ); // �o�׌��ۊǏꏊ
    sb.append("       ,xoha.sum_quantity          = TO_NUMBER(:10) " ); // ���v����
    sb.append("       ,xoha.sum_weight            = TO_NUMBER(:11) " ); // �ύڏd�ʍ��v
    sb.append("       ,xoha.sum_capacity          = TO_NUMBER(:12) ");  // �ύڗe�ύ��v
    sb.append("       ,xoha.performance_management_dept = :13 " ); // ���ъǗ�����
    sb.append("       ,xoha.instruction_dept      = :14 " ); // �w������
    sb.append("       ,xoha.vendor_id             = :15 " ); // �����ID
    sb.append("       ,xoha.vendor_code           = :16 " ); // �����
    sb.append("       ,xoha.vendor_site_id        = :17 " ); // �����T�C�gID
    sb.append("       ,xoha.vendor_site_code      = :18 " ); // �����T�C�g
    sb.append("       ,xoha.shipped_date          = :19 "); // �o�ɓ�
    sb.append("       ,xoha.arrival_date          = :20 "); // ���ד�
    sb.append("       ,xoha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("       ,xoha.last_update_date      = SYSDATE "             ); // �ŏI�X�V��
    sb.append("       ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id = :21; "); // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂��B
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
      Date   shippedDate         = (Date)hdrRow.getAttribute("ShippedDate");             // �o�ɗ\���
      String fixClass            = (String)hdrRow.getAttribute("FixClass");              // ���z�m��
      Number shipWhseId          = (Number)hdrRow.getAttribute("ShipWhseId");            // �o�ɑq��ID
      String shipWhseCode        = (String)hdrRow.getAttribute("ShipWhseCode");          // �o�ɑq��
      String sumQuantity         = XxcmnUtility.stringValue((Number)hdrRow.getAttribute("SumQuantity")); // ���v����
      String sumWeight           = (String)hdrRow.getAttribute("SumWeight");             // �ύڏd�ʍ��v
      sumWeight = XxcmnUtility.commaRemoval(sumWeight);
      String sumCapacity         = (String)hdrRow.getAttribute("SumCapacity");           // �ύڗe�ύ��v
      sumCapacity = XxcmnUtility.commaRemoval(sumCapacity);
      String reqDeptCode         = (String)hdrRow.getAttribute("ReqDeptCode");           // �˗�����
      String instDeptCode        = (String)hdrRow.getAttribute("ReqDeptCode");          // �w������
      Number vendorId            = (Number)hdrRow.getAttribute("VendorId");              // �����ID
      String vendorCode          = (String)hdrRow.getAttribute("VendorCode");            // �����
      Number shipToId            = (Number)hdrRow.getAttribute("ShipToId");              // �z����ID
      String shipToCode          = (String)hdrRow.getAttribute("ShipToCode");            // �z����
      Number orderHeaderId       = (Number)hdrRow.getAttribute("OrderHeaderId");         // �󒍃w�b�_�A�h�I��ID
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderTypeId));      // �����敪
      cstmt.setInt(i++, XxcmnUtility.intValue(customerId));       // �ڋqID
      cstmt.setString(i++, customerCode);                         // �ڋq
      cstmt.setString(i++, instructions);                         // �E�v
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // �o�ח\���(=�o�ɓ�)  
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // ���ח\���(=�o�ɓ�)  
      cstmt.setString(i++, fixClass);                             // ���z�m��
      cstmt.setInt(i++, XxcmnUtility.intValue(shipWhseId));       // �o�ɑq��ID
      cstmt.setString(i++, shipWhseCode);                         // �o�ɑq��
      cstmt.setString(i++, sumQuantity);                          // ���v����
      cstmt.setString(i++, sumWeight);                            // �ύڏd�ʍ��v
      cstmt.setString(i++, sumCapacity);                          // �ύڗe�ύ��v
      cstmt.setString(i++, reqDeptCode);                          // �˗�����
      cstmt.setString(i++, instDeptCode);                         // �w������
      cstmt.setInt(i++, XxcmnUtility.intValue(vendorId));         // �����ID
      cstmt.setString(i++, vendorCode);                           // �����
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToId));         // �z����ID
      cstmt.setString(i++, shipToCode);                           // �z����
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // �o�ד�  
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));    // ���ד�(=�o�ɓ�)  
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));    // �󒍃w�b�_�A�h�I��ID

      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s) 
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      // �������ɃG���[�����������ꍇ��z�肷��
      try 
      {
        cstmt.close();
      } catch(SQLException s) 
      {
          // ���[���o�b�N
          XxpoUtility.rollBack(getOADBTransaction());
          XxcmnUtility.writeLog(getOADBTransaction(),
                                XxpoConstants.CLASS_AM_XXPO443001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr

  /***************************************************************************
   * �����������b�Z�[�W�\�����s�����\�b�h�ł��B
   * @param tokenName - �g�[�N���l
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void putSuccessMessage(
    String tokenName
  ) throws OAException
  {
    // �g�[�N���𐶐����܂��B
    MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,tokenName) };
    // �����������b�Z�[�W
    throw new OAException(
      XxcmnConstants.APPL_XXCMN,
      XxcmnConstants.XXCMN05001, 
      tokens,
      OAException.INFORMATION, 
      null);
  } // putSuccessMessage

  /***************************************************************************
   * ���փ{�^���������̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �w�b�_�r���[�I�u�W�F�N�g
   * @param row - �w�b�_�s�I�u�W�F�N�g
   * @param exceptions - �G���[���i�[�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkNext(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // �˗������K�{�`�F�b�N
    Object reqDeptCode = row.getAttribute("ReqDeptCode");
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
    // �����K�{�`�F�b�N
    Object vendorCode = row.getAttribute("VendorCode");
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

    // �z����K�{�`�F�b�N
    Object shipToCode = row.getAttribute("ShipToCode");
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

    // �o�ɑq�ɕK�{�`�F�b�N
    Object shipWhseCode = row.getAttribute("ShipWhseCode");
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

    // �o�ɓ��K�{�`�F�b�N
    Object shippedDate = row.getAttribute("ShippedDate");
    if (XxcmnUtility.isBlankOrNull(shippedDate)) 
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
  } // chkNext

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkOrderLine(
    String exeType
  ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[List

    // �x���ԕi�쐬�w�b�_VO�擾
    XxpoProvisionRtnMakeHeaderVOImpl hdrVo = getXxpoProvisionRtnMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();

    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate");  // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),shippedDate)) 
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

    // �x���ԕi�v�񌟍�VO
    OAViewObject svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId");  // ��\���i�\ID
    String listIdVendor = (String)hdrRow.getAttribute("PriceList");          // ����承�i�\ID    

    // �����Ώۂ��擾���܂��B
    XxpoProvisionRtnMakeLineVOImpl vo = getXxpoProvisionRtnMakeLineVO1();

    // �K�p��(���ɓ�)�̐ݒ�(�ԕi�̏ꍇ�A���ɓ�=�o�ɓ�)
    Date arrivalDate = shippedDate;

    // �X�V�s�擾
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((updRows != null) || (updRows.length > 0))
    {
      OARow updRow = null;

      for (int i = 0; i < updRows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        updRow = (OARow)updRows[i];
        // �X�V�`�F�b�N����
        chkOrderLineUpd(hdrRow, vo, updRow, exceptions);

        Number invItemId = (Number)updRow.getAttribute("InvItemId"); // INV�i��ID
        String itemNo = (String)updRow.getAttribute("ItemNo");       // �i��No
        String dbItemNo = (String)updRow.getAttribute("DbItemNo");   // �i��No(DB)
        String unitPrice = (String)updRow.getAttribute("UnitPrice"); // �P��
        String reqQuantity = (String)updRow.getAttribute("ReqQuantity");  // �˗���

        // �G���[���Ȃ��ꍇ
        if (exceptions.size() == 0) {
          // �P���������͂ł̏ꍇ
          if (XxcmnUtility.isBlankOrNull(unitPrice)) 
          {
            // �P�����o����
            Number unitPriceNum = XxpoUtility.getUnitPrice(
                                         getOADBTransaction(),
                                         invItemId,
                                         listIdVendor,
                                         listIdRepresent,
                                         arrivalDate,
                                         itemNo);

            // �擾�ł��Ȃ������ꍇ
            if (XxcmnUtility.isBlankOrNull(unitPriceNum)) 
            {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          updRow.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10201));
            // �擾�ł����ꍇ
            } else 
            {
              updRow.setAttribute("UnitPriceNum", unitPriceNum);
            }
          // �P�������͂���Ă���ꍇ
          } else 
          {
            updRow.setAttribute("UnitPriceNum", unitPrice);
          }
          // ���v�d�ʁE���v�e�ς̎Z�o
          HashMap retMap = XxpoUtility.calcTotalValue(getOADBTransaction(),
                                                      itemNo,
                                                      XxcmnUtility.commaRemoval(reqQuantity));
          String retCode = (String)retMap.get("retCode");
          // �߂�l���G���[�̏ꍇ
          if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
          {
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                       XxpoConstants.TOKEN_NAME_CALC_ERR) };
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  updRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN05002,
                                  tokens));
          } else 
          {
            // �d�ʁA�e�ςɃZ�b�g
            updRow.setAttribute("Weight", (String)retMap.get("sumWeight"));
            updRow.setAttribute("Capacity", (String)retMap.get("sumCapacity"));
          }
        }
      }
    }

    // �}���s�擾
    Row[] insRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_Y);
    if ((insRows != null) || (insRows.length > 0) )
    {
      OARow insRow = null;
      for (int i = 0; i < insRows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        insRow = (OARow)insRows[i];
        String itemNo = (String)insRow.getAttribute("ItemNo");  // �i��No
        String reqQuantity = (String)insRow.getAttribute("ReqQuantity");  // �˗���
        // �}���s�`�F�b�N����
        if (!chkOrderLineIns(hdrRow, vo, insRow, exceptions, exeType))
        {
          String unitPrice = (String)insRow.getAttribute("UnitPrice");  // �P��          
          // �P���������͂̏ꍇ�A�P�����o���s���B
          if (XxcmnUtility.isBlankOrNull(unitPrice)) 
          {
            // �}���s�`�F�b�N�����ŃG���[�ɂȂ�Ȃ������ꍇ�A�P�����o
            Number invItemId = (Number)insRow.getAttribute("InvItemId");  // INV�i��ID

            // �P�����o����
            Number unitPriceNum = XxpoUtility.getUnitPrice(
                                         getOADBTransaction(),
                                         invItemId,
                                         listIdVendor,
                                         listIdRepresent,
                                         arrivalDate,
                                         itemNo);
            // �擾�ł��Ȃ������ꍇ
            if (XxcmnUtility.isBlankOrNull(unitPriceNum)) 
            {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          insRow.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10201));
            // �擾�ł����ꍇ
            } else 
            {
              insRow.setAttribute("UnitPriceNum", unitPriceNum);
            }
          // �P�������͂���Ă���ꍇ
          } else 
          {
            insRow.setAttribute("UnitPriceNum", unitPrice);
          }

          // ���v�d�ʁE���v�e�ς̓��o
          HashMap retMap = XxpoUtility.calcTotalValue(getOADBTransaction(),
                                                      itemNo,
                                                      XxcmnUtility.commaRemoval(reqQuantity));
          String retCode = (String)retMap.get("retCode");
          // �߂�l���G���[�̏ꍇ
          if (!XxcmnConstants.API_RETURN_NORMAL.equals(retCode)) 
          {
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_PROCESS,
                                                       XxpoConstants.TOKEN_NAME_CALC_ERR) };
            exceptions.add( new OAAttrValException(
                                  OAAttrValException.TYP_VIEW_OBJECT,          
                                  vo.getName(),
                                  insRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXCMN, 
                                  XxcmnConstants.XXCMN05002,
                                  tokens));
          } else
          {
            // �d�ʁA�e�ςɃZ�b�g
            insRow.setAttribute("Weight",   (String)retMap.get("sumWeight"));
            insRow.setAttribute("Capacity", (String)retMap.get("sumCapacity"));
          }
        }
      }
    }

    // �G���[���������ꍇ�ɃG���[���X���[���܂��B
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
   ***************************************************************************
   */
  public void chkOrderLineUpd(
    OARow hdrRow,
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  )
  {
    // �����擾
    Object orderLineNum = row.getAttribute("OrderLineNumber");  // ���הԍ�
    Object itemNo = row.getAttribute("ItemNo"); // �i�ڃR�[�h
    Object reqQuantity = row.getAttribute("ReqQuantity"); // �˗�����
    Object unitPrice = row.getAttribute("UnitPrice"); // �P��

    // �K�{�`�F�b�N(�i�ڃR�[�h)
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
    // �i�ڂ����͂���Ă���ꍇ�A�i�ڏd���`�F�b�N
    } else 
    {
      Row[] chkRows = vo.getAllRowsInRange();
      // ����VO�Ƀ��R�[�h�����݂���ꍇ�̂ݍs��
      if ((chkRows != null) || (chkRows.length > 0)) 
      {
        OARow chkRow = null;
        for (int i = 0; i < chkRows.length; i++) 
        {
          // i�Ԗڂ̍s���擾
          chkRow = (OARow)chkRows[i];
          // �i�ڏd���`�F�b�N
          if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))  // �Ⴄ���׍s
            &&(XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))))               // �����i��  
          {
              exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          vo.getName(),
                          row.getKey(),
                          "ItemNo",
                          itemNo,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10151));
              break;
          }
        }
      }
    }

    // �K�{�`�F�b�N(�˗�����)
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

    // �˗����ʂ����͂���Ă���ꍇ�A���l�`�F�b�N
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
      // �˗����ʂ����l�ł���ꍇ�A���ʃ`�F�b�N
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
        }
      }
    }

    // �P���`�F�b�N
    if (!XxcmnUtility.isBlankOrNull(unitPrice)) 
    {
      // ���l�`�F�b�N
      if (!XxcmnUtility.chkNumeric(unitPrice, 7, 2)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "UnitPrice",
                              unitPrice,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
      }
    }
  } // chkOrderLineUpd

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B(�}���p)
   * @return boolean - True:�G���[�L��  False:�G���[����
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @param vo     - �r���[�I�u�W�F�N�g
   * @param row    - ���׍s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkOrderLineIns (
    OARow hdrRow,
    OAViewObject vo,
    OARow row,
    ArrayList exceptions,
    String exeType
  ) throws OAException
  {
    boolean errFlag = false;  // �G���[�t���O

    // �����擾
    Object orderLineNum = row.getAttribute("OrderLineNumber");  // ���הԍ�
    Object itemNo = row.getAttribute("ItemNo");                 // �i�ڃR�[�h
    Object futaiCode = row.getAttribute("FutaiCode");           // �t�уR�[�h
    Object reqQuantity = row.getAttribute("ReqQuantity");       // �˗�����
    Object description = row.getAttribute("LineDescription");   // ���l
    Object unitPrice = row.getAttribute("UnitPrice");           // �P��
    // ���׍s�ɉ������͂���Ă��Ȃ��ꍇ��True�ŏI��
    if (XxcmnUtility.isBlankOrNull(itemNo)
      && XxcmnUtility.isBlankOrNull(futaiCode)
      && XxcmnUtility.isBlankOrNull(reqQuantity)
      && XxcmnUtility.isBlankOrNull(description)
      && XxcmnUtility.isBlankOrNull(unitPrice)
    ) 
    {
      return true;
    }

    // �K�{�`�F�b�N(�i�ڃR�[�h)
    if (XxcmnUtility.isBlankOrNull(itemNo)
      && (   !XxcmnUtility.isBlankOrNull(futaiCode)
          || !XxcmnUtility.isBlankOrNull(reqQuantity)
          || !XxcmnUtility.isBlankOrNull(description)
          || !XxcmnUtility.isBlankOrNull(unitPrice))
       ) 
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

    // �i�ڂ����͂���Ă���ꍇ�A�d���`�F�b�N
    } else 
    {
      // �`�F�b�N�p�S�s�擾
      Row[] chkRows = vo.getAllRowsInRange();
      // ���׌���������ꍇ
      if ((chkRows != null) || (chkRows.length > 0)) 
      {
        OARow chkRow = null;
        for (int i = 0; i < chkRows.length; i++) 
        {
          // i�Ԗڂ̍s���擾
          chkRow = (OARow)chkRows[i];
          // �i�ڏd���`�F�b�N
          if (!XxcmnUtility.isEquals(orderLineNum, chkRow.getAttribute("OrderLineNumber"))  // �Ⴄ���׍s
            &&(XxcmnUtility.isEquals(itemNo, chkRow.getAttribute("ItemNo"))))               // �����i��  
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

    // �K�{�`�F�b�N(�˗�����)
    if (XxcmnUtility.isBlankOrNull(reqQuantity)
      && (  !XxcmnUtility.isBlankOrNull(itemNo)
         || !XxcmnUtility.isBlankOrNull(futaiCode)
         || !XxcmnUtility.isBlankOrNull(description)
         || !XxcmnUtility.isBlankOrNull(unitPrice))
        ) 
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

    // �˗����ʂ����͂���Ă���ꍇ�A���l�`�F�b�N
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

      // �˗����ʂ����l�ł���ꍇ�A���ʃ`�F�b�N
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
    // �P���`�F�b�N
    if (!XxcmnUtility.isBlankOrNull(unitPrice)) 
    {
      // ���l�`�F�b�N
      if (!XxcmnUtility.chkNumeric(unitPrice, 7, 2)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              vo.getName(),
                              row.getKey(),
                              "UnitPrice",
                              unitPrice,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));
        errFlag = true;
      }
    }
    return errFlag;
  } // chkOrderLineIns

  /***************************************************************************
   * ���z�m��O�`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   ***************************************************************************
   */
    public void chkAmountFix(
      OAViewObject vo,
      OARow row,
      ArrayList exceptions
    )
    {
      // �݌ɉ�v���ԃN���[�Y�`�F�b�N
      Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
      if (XxpoUtility.chkStockClose(
            getOADBTransaction(),
            shippedDate
           )
          ) 
      {
        // �o�ד��̔N�������߂ɃN���[�Y�����݌ɉ�v���ԔN���̏ꍇ�̓G���[�B
        exceptions.add(
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,
            vo.getName(),
            row.getKey(),
            "ShippedDate",
            shippedDate,
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10119
          )
        );
      }

      // �X�e�[�^�X�`�F�b�N
      String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
      if(!XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
      {
        // �X�e�[�^�X���o�׎��ьv��ς݂ł͂Ȃ��ꍇ�̓G���[�B
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "TransStatus",
                              transStatus,
                              XxcmnConstants.APPL_XXPO, 
                              XxpoConstants.XXPO10145));
      }

      // ���z�m��ς݃`�F�b�N
      String fixClass = (String)row.getAttribute("FixClass"); // ���z�m��敪
      if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
      {
        // �G���[���b�Z�[�W�͔����敪���ɕ\��
        Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
        // ���z�m��ς�(1)�̏ꍇ�̓G���[�B
        exceptions.add(
          new OAAttrValException(
            OAAttrValException.TYP_VIEW_OBJECT,
            vo.getName(),
            row.getKey(),
            "OrderTypeId",
            orderType,
            XxcmnConstants.APPL_XXPO,
            XxpoConstants.XXPO10125
          )
        );
      }
    } // chkAmountFix

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���A�󒍖��׃A�h�I���̃��b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void chkLockAndExclusive(
      OAViewObject vo,
      OARow row
    ) throws OAException
    {

      //���b�N�Ώۂ��擾���܂��B
      Number orderHeaderId = (Number)row.getAttribute("OrderHeaderId"); //�󒍃w�b�_�A�h�I��ID
      //�󒍃^�C�vID���擾���܂��B
      Number orderType = (Number)row.getAttribute("OrderTypeId");       //�����敪ID

      //���b�N�擾���ʃ��\�b�h�����s���܂��B
      if (!XxpoUtility.getXxwshOrderLock(getOADBTransaction(), orderHeaderId))
      //�߂�l��false(�G���[)�̏ꍇ        
      {
        //���[���o�b�N���܂��B
        XxpoUtility.rollBack(getOADBTransaction());

        //�G���[���b�Z�[�W 
        throw new OAAttrValException(
          OAAttrValException.TYP_VIEW_OBJECT,
          vo.getName(),
          row.getKey(),
          "OrderTypeId",
          orderType,
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO10138
        );
      }

      //VO�̍ŏI�X�V�����擾���܂��B
      String xohaLastUpdateDate = (String)row.getAttribute("XohaLastUpdateDate"); //�ŏI�X�V��(�󒍃w�b�_)
      String xolaLastUpdateDate = (String)row.getAttribute("XolaLastUpdateDate"); //�ŏI�X�V��(�󒍖���)

      //�r���`�F�b�N(VO�̍ŏI�X�V����DB�̍ŏI�X�V�����r)���s���܂��B
      if (!XxpoUtility.chkExclusiveXxwshOrder(
            getOADBTransaction(),
            orderHeaderId,
            xohaLastUpdateDate,
            xolaLastUpdateDate
            )
          )
      {
        //���[���o�b�N���܂��B
        XxpoUtility.rollBack(getOADBTransaction());

        //�r���G���[���b�Z�[�W
        throw new OAAttrValException(
          OAAttrValException.TYP_VIEW_OBJECT,
          vo.getName(),
          row.getKey(),
          "OrderTypeId",
          orderType,
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10147
        );
      }
    } //chkLockAndExclusive

  /***************************************************************************
   * �y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
    public void checkBoxOff() throws OAException
    {
      //�����Ώۂ��擾���܂��B
      OAViewObject vo = getXxpoProvisionRtnSumResultVO1();
      Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

      //���I���`�F�b�N���s���܂��B
      if ((rows != null) || (rows.length != 0))
      {
        OARow row = null;
        for (int i = 0; i < rows.length; i++)
        {
          //i�Ԗڂ̍s���擾
          row = (OARow)rows[i];
          row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
        }
      }
    } //checkBoxOff

  /***************************************************************************
   * �폜�����̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo     - �r���[�I�u�W�F�N�g
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @param row    - ���׍s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkOrderLineDel(
    OAViewObject vo,
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
   * �x���ԕi�쐬�w�b�_��ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void handleEventAllOnHdr(
    OARow prow
  ) throws OAException
  {
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.FALSE); // �x������{�^��
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
   * �x���ԕi�쐬�w�b�_��ʂ̍��ڂ�S��TRUE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void handleEventAllOffHdr(
    OARow prow
    ) throws OAException
  {
    prow.setAttribute("ProvCancelBtnReject"          , Boolean.TRUE); // �x������{�^��
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
   * �x���ԕi�쐬�w�b�_��ʂ̐V�K���̍��ڐ��䏈�����s�����\�b�h�ł��B
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
    prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
    prow.setAttribute("FixReadOnly", Boolean.TRUE);         // ���z�m��`�F�b�N�{�b�N�X
  } // handleEventInsHdr

  /***************************************************************************
   * �x���ԕi�쐬�w�b�_��ʂ̍X�V���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v ���x���ԕi�ł͖��g�p
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
    // �X�e�[�^�X���擾
    String transStatus = (String)row.getAttribute("TransStatus");

    // �X�e�[�^�X���u���͒��v�̏ꍇ
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      prow.setAttribute("ProvCancelBtnReject", Boolean.FALSE); // �x������{�^��
      prow.setAttribute("FixReadOnly", Boolean.TRUE);         // ���z�m��`�F�b�N�{�b�N�X

      // ��̃^�C�v���擾
      String rcvType = (String)row.getAttribute("RcvType");
      // ��̃^�C�v���u�ꕔ���їL��v�̏ꍇ
      if (XxpoConstants.RCV_TYPE_5.equals(rcvType)) 
      {
        prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��
      }

    // �X�e�[�^�X���u�o�׎��ьv��ρv�̏ꍇ
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus))
    {
      // �u�o�׎��ьv��ρv���ڐ���
      prow.setAttribute("OrderTypeReadOnly", Boolean.TRUE);   // �����敪
      prow.setAttribute("ReqDeptReadOnly", Boolean.TRUE);     // �˗�����
      prow.setAttribute("VendorReadOnly", Boolean.TRUE);      // �����
      prow.setAttribute("ShipToReadOnly", Boolean.TRUE);      // �z����
      prow.setAttribute("ShipWhseReadOnly", Boolean.TRUE);    // �o�ɑq��
      prow.setAttribute("ShippedDateReadOnly", Boolean.TRUE); // �o�ɓ�
      prow.setAttribute("ProvCancelBtnReject", Boolean.TRUE); // �x������{�^��

      // ���z�m��t���O���擾
      String fixClass = (String)row.getAttribute("FixClass");
      // �u���z���m��v���ڐ���
      if (XxpoConstants.FIX_CLASS_OFF.equals(fixClass)) 
      {
        prow.setAttribute("ShippingInstructionsReadOnly", Boolean.FALSE);    // �E�v
      // �u���z�m��ρv���ڐ���
      } else 
      {
        prow.setAttribute("ShippingInstructionsReadOnly", Boolean.TRUE);    // �E�v
      }
      prow.setAttribute("FixReadOnly", Boolean.FALSE);         // ���z�m��`�F�b�N�{�b�N�X
    }
  } // handleEventUpdHdr

  /***************************************************************************
   * �x���ԕi�쐬���׉�ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
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
    // �X�e�[�^�X���擾
    String transStatus = (String)hdrRow.getAttribute("TransStatus");

    // ���͒��̏ꍇ
    if (XxpoConstants.PROV_STATUS_NRT.equals(transStatus)) 
    {
      prow.setAttribute("AddRowBtnRender", Boolean.TRUE); // �s�}���{�^��

    // �o�׎��ьv��ς̏ꍇ
    } else if (XxpoConstants.PROV_STATUS_SJK.equals(transStatus)) 
    {
      prow.setAttribute("AddRowBtnRender", Boolean.FALSE); // �s�}���{�^��
    }
  } // handleEventUpdLine

//  ---------------------------------------------------------------
//  ---    Default Method
//  ---------------------------------------------------------------
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo440007j.server", "XxpoProvisionRtnSummaryAMLocal");
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
   * Container's getter for OrderTypeVO1
   */
  public OAViewObjectImpl getOrderTypeVO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderTypeVO1");
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
   * Container's getter for NotifStatusVO1
   */
  public OAViewObjectImpl getNotifStatusVO1()
  {
    return (OAViewObjectImpl)findViewObject("NotifStatusVO1");
  }


  /**
   * 
   * Container's getter for OrderType2VO1
   */
  public OAViewObjectImpl getOrderType2VO1()
  {
    return (OAViewObjectImpl)findViewObject("OrderType2VO1");
  }

  /**
   * 
   * Container's getter for TransStatus2VO1
   */
  public OAViewObjectImpl getTransStatus2VO1()
  {
    return (OAViewObjectImpl)findViewObject("TransStatus2VO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnSumResultVO1
   */
  public XxpoProvisionRtnSumResultVOImpl getXxpoProvisionRtnSumResultVO1()
  {
    return (XxpoProvisionRtnSumResultVOImpl)findViewObject("XxpoProvisionRtnSumResultVO1");
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
   * Container's getter for XxpoProvisionRtnMakeHeaderVO1
   */
  public XxpoProvisionRtnMakeHeaderVOImpl getXxpoProvisionRtnMakeHeaderVO1()
  {
    return (XxpoProvisionRtnMakeHeaderVOImpl)findViewObject("XxpoProvisionRtnMakeHeaderVO1");
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
   * Container's getter for FreightVO1
   */
  public OAViewObjectImpl getFreightVO1()
  {
    return (OAViewObjectImpl)findViewObject("FreightVO1");
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
   * Container's getter for XxpoProvisionRtnMakeHeaderPVO1
   */
  public XxpoProvisionRtnMakeHeaderPVOImpl getXxpoProvisionRtnMakeHeaderPVO1()
  {
    return (XxpoProvisionRtnMakeHeaderPVOImpl)findViewObject("XxpoProvisionRtnMakeHeaderPVO1");
  }


  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeLinePVO1
   */
  public XxpoProvisionRtnMakeLinePVOImpl getXxpoProvisionRtnMakeLinePVO1()
  {
    return (XxpoProvisionRtnMakeLinePVOImpl)findViewObject("XxpoProvisionRtnMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeTotalVO1
   */
  public XxpoProvisionRtnMakeTotalVOImpl getXxpoProvisionRtnMakeTotalVO1()
  {
    return (XxpoProvisionRtnMakeTotalVOImpl)findViewObject("XxpoProvisionRtnMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoProvisionRtnMakeLineVO1
   */
  public XxpoProvisionRtnMakeLineVOImpl getXxpoProvisionRtnMakeLineVO1()
  {
    return (XxpoProvisionRtnMakeLineVOImpl)findViewObject("XxpoProvisionRtnMakeLineVO1");
  }










}