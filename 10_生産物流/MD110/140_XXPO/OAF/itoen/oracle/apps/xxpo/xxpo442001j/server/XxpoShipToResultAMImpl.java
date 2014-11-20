/*============================================================================
* �t�@�C���� : XxpoShipToResultAMImpl
* �T�v����   : ���Ɏ��їv��A�v���P�[�V�������W���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �V���`��     �V�K�쐬
* 2008-07-01 1.1  ��r���     �����ύX�v���Ή�#147,#149,ST�s�#248�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;

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
 * ���Ɏ��їv���ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE �V�� �`��
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShipToResultAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShipToResultAMImpl()
  {
  }

  /***************************************************************************
   * ���Ɏ��їv���ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // �x���˗��v�񌟍�VO
    XxpoProvSearchVOImpl vo = getXxpoProvSearchVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (vo.getFetchedRowCount() == 0)
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);

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
      row.setNewRowState(OARow.STATUS_INITIALIZED);

      // �N���^�C�v���u32�F�p�b�J�[��O���H��p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_32.equals(exeType)) 
      {
        // ���[�U�[���擾 
        HashMap userInfo = XxpoUtility.getUserData(getOADBTransaction());
        // �d����ɒl��ݒ�
        row.setAttribute("VendorId",   userInfo.get("VendorId"));
        row.setAttribute("VendorCode", userInfo.get("VendorCode"));
        row.setAttribute("VendorName", userInfo.get("VendorName"));

      }
    }
  } // initializeList
  
  /***************************************************************************
   * ���Ɏ��їv���ʂ̌����������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchList(
   String exeType
  ) throws OAException
  {
    // ���Ɏ��ь���VO�擾
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
    shParams.put("exeType", exeType);                                    // �N���^�C�v
    // ���Ɏ��ь���VO�擾
     XxpoShipToResultVOImpl vo = getXxpoShipToResultVO1();
    // ���������s���܂��B
    vo.initQuery(shParams);

  } // doSearchList

  /***************************************************************************
   * ���Ɏ��їv���ʂ̑S�����ɏ����O�̖��I���`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkBeforeDecision() throws OAException
  {
    // ���Ɏ��ь���VO�擾
    OAViewObject vo = getXxpoShipToResultVO1();
    
    // �I�����ꂽ���R�[�h���擾
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
    chkNonChoice(rows);
    
  } // chkBeforeDecision

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
   * ���Ɏ��їv���ʂ̑S�����ɏ������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doDecisionList(
   String exeType
  ) throws OAException
  {   
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag      = false; // ���s�t���O

    // �����Ώۂ��擾���܂��B
    OAViewObject vo = getXxpoShipToResultVO1();
    Row[] rows   = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    
    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      // �G���[�`�F�b�N
      chkInputAll(vo, row, exceptions);

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
      if(chkLockAndExclusive(vo, row))
      {
        // �S�����ɂ̎��ѓo�^����
        Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
        Date arriveDate = (Date)row.getAttribute("ArrivalDate");
        if((XxpoUtility.updateOrderExecute(getOADBTransaction(),
                                orderHeader,
                                XxpoConstants.REC_TYPE_30,
                                arriveDate)))
        {
          exeFlag = true;
        } else
        {
          //�g�[�N������
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                        "�S������") };
          // �G���[���b�Z�[�W�o��
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                 XxcmnConstants.XXCMN05002, 
                                 tokens);
        }
      }
    }    
    // ���s���ꂽ�ꍇ
    if (exeFlag) 
    {
      // �R�~�b�g���s
      XxpoUtility.commit(getOADBTransaction());
      // �Č������s���܂��B
      doSearchList(exeType);
      // �����������b�Z�[�W�o��
      XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_ALL_SHIP_TO);

    } 
  } // doDecisionList

  /***************************************************************************
   * ���b�N�E�r���������s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkLockAndExclusive(
    OAViewObject vo,
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
     // �r���`�F�b�NOK
    } else
    {
      return true;
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * �˗�No���ƂɃ`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkInputAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {

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

    // ���і����̓`�F�b�N���s���܂��B
     Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
    if(!XxpoUtility.chkOrderResult(getOADBTransaction(),
                                   orderHeader,
                                   XxpoConstants.REC_TYPE_30))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "OrderHeaderId",
                            orderHeader,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10130)); 

    }

    // ���b�g�X�e�[�^�X�`�F�b�N���s���܂��B
    String requestNo = (String)row.getAttribute("RequestNo");
    if(!(XxpoUtility.chkLotStatus(getOADBTransaction(),
                                  requestNo)))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "RequestNo",
                            requestNo,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10210));
    }
  } // chkInputAll

 
  /***************************************************************************
   * �y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // �����Ώۂ��擾���܂��B
    OAViewObject vo = getXxpoShipToResultVO1();
    Row[] rows      = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // �`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
    if((rows != null) || (rows.length != 0))
    {
      OARow row = null;
      for(int i=0;i<rows.length;i++)
      {
        //i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        row.setAttribute("MultiSelect", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * ���Ɏ��ѓ��̓w�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param reqNo   - �˗�No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
     // ���Ɏ��э쐬�w�b�_PVO
      XxpoShipToHeaderPVOImpl pvo = getXxpoShipToHeaderPVO1(); 
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

      // �˗�No�Ō��������s
      doSearchHdr(reqNo);

      // ���Ɏ��ѓ��̓w�b�_VO�擾
      XxpoShipToHeaderVOImpl vo = getXxpoShipToHeaderVO1();
      OARow row = (OARow)vo.first();
      // �X�V�����ڐ���
      handleEventUpdHdr(exeType, prow, row);
      // ���׍s�̌���
      doSearchLine();

  } // initializeHdr  

  /***************************************************************************
   * ���Ɏ��ѓ��̓w�b�_��ʂ̌����������s�����\�b�h�ł��B
   * @param  reqNo - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */ 
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
     // ���Ɏ��э쐬�w�b�_VO�擾
    XxpoShipToHeaderVOImpl vo = getXxpoShipToHeaderVO1();
    // ���������s���܂��B
    vo.initQuery(reqNo);
    vo.first();
    // �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // ���Ɏ��э쐬PVO
      XxpoShipToHeaderPVOImpl pvo = getXxpoShipToHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                             XxcmnConstants.XXCMN10500);

    }
  } // doSearchHdr 

  /***************************************************************************
   * ���Ɏ��ѓ��̓w�b�_��ʂ̎��֏������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList
    boolean exeFlag = false; // ���s�t���O
    
    // ���Ɏ��э쐬�w�b�_VO�擾
    OAViewObject vo = getXxpoShipToHeaderVO1();
    OARow row   = (OARow)vo.first();
    // ���ɓ��K�{���̓`�F�b�N
    chkArrival(vo, row, exceptions);

  } // doNext

  /***************************************************************************
   * ���Ɏ��ѓ��͖��׉�ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param reqNo   - �˗�No
   ***************************************************************************
   */
  public void initializeLine(
    String exeType,
    String reqNo)     
  {
    // ���Ɏ��ѓ��͖���PVO
    XxpoShipToLinePVOImpl pvo = getXxpoShipToLinePVO1();
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

    }

    // �x���w���쐬�w�b�_VO�擾
    OAViewObject vo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)vo.first();
    String fixClass = (String)hdrRow.getAttribute("FixClass");    // ���z�m��ϋ敪
    // ���z�m��敪���u���z�m��ρv�̏ꍇ
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // ������
      prow.setAttribute("ApplyBtnReject", Boolean.TRUE);
    } else
    {
      // �����s��
      prow.setAttribute("ApplyBtnReject", Boolean.FALSE);
    }
  } // initializeLine

  /***************************************************************************
   * ���Ɏ��ѓ��͖��׉�ʂ̌����������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
   public void doSearchLine(
    ) throws OAException
  {
    // ���Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();     
    // �󒍃w�b�_�A�h�I��ID���擾���܂��B
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

    // ���Ɏ��ѓ��͖���VO�擾
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
    // ���������s���܂��B
    vo.initQuery(orderHeaderId);

    // ���Ɏ��э쐬���vVO�擾
    XxpoShipToTotalVOImpl totalVo = getXxpoShipToTotalVO1();
    // ���������s���܂��B
    totalVo.initQuery(orderHeaderId); 

  } // doSearchLine

  /***************************************************************************
   * ���փ{�^���������̓��ɓ��K�{���̓`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkArrival(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    // ���ɓ�
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // �o�ɓ�
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // �V�X�e�����t���擾
    Date currentDate = getOADBTransaction().getCurrentDBDate();
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
    // ���ɓ����������̏ꍇ
    } else if (!XxcmnUtility.chkCompareDate(2, currentDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
    // �o�ɓ������ɓ��̏ꍇ
    } else if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ArrivalDate",
                            arrivalDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10249));

    } 
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkArrival

  /***************************************************************************
   * ���Ɏ��э쐬�w�b�_��ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.FALSE); // ���ɓ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // �E�v

  } // handleEventAllOnHdr

  /***************************************************************************
   * ���Ɏ��э쐬�w�b�_��ʂ̍��ڂ�S��TRUE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
    prow.setAttribute("ArrivalDateReadOnly"          , Boolean.TRUE); // ���ɓ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // �E�v

  } // handleEventAllOffHdr

  /***************************************************************************
   * ���Ɏ��ѓ��̓w�b�_��ʂ̍X�V���̍��ڐ��䏈�����s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param prow    - PVO�s�N���X
   * @param row     - VO�s�N���X
   ***************************************************************************
   */
  public void handleEventUpdHdr(
    String exeType,
    OARow prow,
    OARow row
    )
  {
    // �e����擾
    String notifStatus = (String)row.getAttribute("NotifStatus"); // �ʒm�X�e�[�^�X
    String transStatus = (String)row.getAttribute("TransStatus"); // �X�e�[�^�X
    String fixClass    = (String)row.getAttribute("FixClass");    // ���z�m��ϋ敪

    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
    } else 
    {
      // �ʒm�X�e�[�^�X���u�m��ʒm�ρv�̏ꍇ
      if ((XxpoConstants.NOTIF_STATUS_KTZ.equals(notifStatus))
       && (   XxpoConstants.PROV_STATUS_ZRZ.equals(transStatus) 
           || XxpoConstants.PROV_STATUS_SJK.equals(transStatus)))
      {
        // ���͉�
        handleEventAllOnHdr(prow);
        String freightClass = (String)row.getAttribute("FreightChargeClass"); // �^���敪
        // �^���敪���uON�v�̏ꍇ�͓��ɓ�����s��
        if (XxcmnConstants.STRING_ONE.equals(freightClass)) 
        {
          prow.setAttribute("ArrivalDateReadOnly", Boolean.TRUE);  
        }
      } else
      {
        // �Q�Ƃ̂�
        handleEventAllOffHdr(prow);
      }
    }
  } //  handleEventUpdHdr

  /***************************************************************************
   * ���Ɏ��ѓ��͖��׉�ʂ̓K�p�������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   * @return  HashMap - �߂�l�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    // �`�F�b�N����
    chkOrderLine(exeType);

    // �x���w���쐬�w�b�_VO�擾
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    String newFlag = (String)hdrRow.getAttribute("NewFlag");   // �V�K�t���O
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // �˗�No
    String tokenName = null;

    // �V�K�t���O���uN�F�X�V�v�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // �r���`�F�b�N
      chkLockAndExclusive(hdrVo, hdrRow);
      tokenName = XxpoConstants.TOKEN_NAME_UPD;
    }

    // �X�V����
    if (doUpdate(newFlag, hdrRow, exeType)) 
    {
      // �R�~�b�g����
      XxpoUtility.commit(getOADBTransaction());

      if (XxpoConstants.TOKEN_NAME_UPD.equals(tokenName)) 
      {
        // ������
        initializeHdr(exeType, reqNo);
        initializeLine(exeType, reqNo);
      }
    } else
    {
      // ���[���o�b�N����
      XxpoUtility.rollBack(getOADBTransaction());
      tokenName = null;

    }

    HashMap retParams = new HashMap();
    retParams.put("tokenName", tokenName);
    retParams.put("reqNo", reqNo);

    return retParams; 
    
  } // doApply

  /***************************************************************************
   * �K�p�����̃`�F�b�N���s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkOrderLine(String exeType) throws OAException
  {
    ArrayList exceptions = new ArrayList(100); // �G���[���b�Z�[�W�i�[�pList

    // ���Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShipToHeaderVOImpl hdrVo = getXxpoShipToHeaderVO1();
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
    Date arrivalDate = (Date)hdrRow.getAttribute("ArrivalDate"); // ���ɓ�
    // ���ɓ����ύX����Ă���ꍇ
    if (!XxcmnUtility.isEquals(arrivalDate, hdrRow.getAttribute("DbArrivalDate")))
    {
       priceFlag = true;  
    }

    OAViewObject svo = getXxpoProvSearchVO1();
    OARow srow = (OARow)svo.first();
    String listIdRepresent = (String)srow.getAttribute("RepPriceListId"); // ��\���i�\      
    String listIdVendor    = (String)hdrRow.getAttribute("PriceList");    // ����承�i�\ID

    // �����Ώۂ��擾���܂��B
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
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
        Number invItemId = (Number)updRow.getAttribute("InvItemId"); // INV�i��ID
        String itemNo    = (String)updRow.getAttribute("ItemNo");    // �i��No
        String dbItemNo  = (String)updRow.getAttribute("DbItemNo");  // �i��No(DB)
        
        // �P�����o�t���O��true
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
                                  updRow.getKey(),
                                  "ItemNo",
                                  itemNo,
                                  XxcmnConstants.APPL_XXPO, 
                                  XxpoConstants.XXPO10201));

          } else
          {
            updRow.setAttribute("UnitPriceNum", unitPrice);

          }
        }
      }
    }
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    } 
  } //chkOrderLine   

  /***************************************************************************
   * �X�V�������s�����\�b�h�ł��B
   * @param newFlag - �V�K�t���O N:�X�V
   * @param hdrRow  - �w�b�_�s�I�u�W�F�N�g
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   * @return updateFlag - �X�V�t���O true:�X�V���� false:�X�V�Ȃ�
   ***************************************************************************
   */
  public boolean doUpdate(
    String newFlag,
    OARow hdrRow,
    String exeType
    ) throws OAException
  {

    // �X�V�t���O
    boolean updateFlag = false;
    
    // ���Ɏ��ѓ��͖���VO
    XxpoShipToLineVOImpl vo = getXxpoShipToLineVO1();
    boolean lineExeFlag = false; // ���׎��s�t���O
    boolean hdrExeFlag  = false; // �w�b�_���s�t���O
    
     // ���׍X�V�s�擾
    Row[] updRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    
    if ((updRows != null) || (updRows.length > 0)) 
    {
      OARow updRow = null;
      for (int i = 0; i < updRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        updRow = (OARow)updRows[i];
        // ���l���ύX���ꂽ�ꍇ
        if (!XxcmnUtility.isEquals(updRow.getAttribute("LineDescription"), updRow.getAttribute("DbLineDescription")))
        {
          // �X�V����
          updateOrderLine(updRow);
          // ���׎��s�t���O��true�ɕύX
          lineExeFlag = true;

        }        
      }
    }

      // �w�b�_�X�V�̏ꍇ
    if (XxcmnConstants.STRING_N.equals(newFlag)) 
    {
      // ���ɓ��܂��͓E�v���ύX���ꂽ�ꍇ
      if ((!XxcmnUtility.isEquals(hdrRow.getAttribute("ArrivalDate"), hdrRow.getAttribute("DbArrivalDate")))
      ||   !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"), hdrRow.getAttribute("DbShippingInstructions")))
      {
        // �X�V����
        updateOrderHdr(hdrRow);
        // �ړ����b�g�ڍׂ̍X�V
        updateMovLotDetails(hdrRow);
        // �w�b�_���s�t���O��true�ɕύX
        hdrExeFlag = true;
      }
    }  
    if (hdrExeFlag || lineExeFlag) 
    {
      updateFlag = true;
      return updateFlag;
    } else
    {
      return updateFlag;
    }  

  } // doUpdate 

  /*****************************************************************************
   * �󒍖��׃A�h�I���̃f�[�^���X�V���܂��B
   * @param insRow - �}���Ώۍs
   * @throws OAException - OA��O
   ****************************************************************************/
  public void updateOrderLine(
    OARow insRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.unit_price        = :1 " ); // �P��
    sb.append("        ,xola.line_description  = :2 " ); // ���l
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID "); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date  = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xola.order_line_id = :3 ; "); // �󒍖��׃A�h�I��ID
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �����擾
      Number unitPrice       = (Number)insRow.getAttribute("UnitPriceNum");     // �P��
      String lineDescription = (String)insRow.getAttribute("LineDescription");  // �E�v
      Number orderLineId     = (Number)insRow.getAttribute("OrderLineId");      // �󒍖��׃A�h�I��ID

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(unitPrice));            // �P��
      cstmt.setString(2, lineDescription);                          // �E�v     
      cstmt.setInt(3, XxcmnUtility.intValue(orderLineId));          // �󒍖��׃A�h�I��ID

      // PL/SQL���s
      cstmt.execute();

      // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̃f�[�^���X�V���܂��B
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
    sb.append("  SET    xoha.arrival_date                = :1 " ); // ���ד�
    sb.append("        ,xoha.shipping_instructions       = :2 " ); // �o�׎w��
    sb.append("        ,xoha.last_updated_by       = FND_GLOBAL.USER_ID "  ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date      = SYSDATE "             ); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID " ); // �ŏI�X�V���O�C�� 
    sb.append("  WHERE  xoha.order_header_id = :3 ; ");   // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �����擾
      Date   arrivalDate    = (Date)hdrRow.getAttribute("ArrivalDate");             // ���ɓ�
      String instructions   = (String)hdrRow.getAttribute("ShippingInstructions");  // �E�v
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); 

      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(1, XxcmnUtility.dateValue(arrivalDate)); // ���ד�
      cstmt.setString(2, instructions);                      // �o�׎w��
      cstmt.setInt(3, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                               XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHdr  

  /*****************************************************************************
   * �ړ����b�g�ڍׂ̃f�[�^���X�V���܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void updateMovLotDetails(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "updateMovLotDetails";

    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxinv_mov_lot_details xmld ");
    sb.append("  SET   xmld.actual_date       = :1 " );                 // ���ѓ�
    sb.append("       ,xmld.last_updated_by   = FND_GLOBAL.USER_ID  "); // �ŏI�X�V��
    sb.append("       ,xmld.last_update_date  = SYSDATE ");             // �ŏI�X�V��
    sb.append("       ,xmld.last_update_login = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE xmld.mov_line_id IN ( SELECT xola.order_line_id  " ); // ����ID
    sb.append("                              FROM   xxwsh_order_lines_all xola "); // �󒍖��׃A�h�I��
    sb.append("                              WHERE  xola.order_header_id = :2 ");  // �󒍃w�b�_�A�h�I��ID
    sb.append("                            )  ");
    sb.append("  AND   xmld.record_type_code   = '30'    "); // ���R�[�h�^�C�v�F����
    sb.append("  AND   xmld.document_type_code = '30' ;  "); // �����^�C�v�F�x���w��
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Date   actualDate = (Date)hdrRow.getAttribute("ArrivalDate");      // ���ɓ�
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId");  // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));            // �o�ד�
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));           // �󒍃w�b�_�A�h�I��ID
     
      //PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
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
                                XxpoConstants.CLASS_AM_XXPO442001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
          throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // updateMovLotDetails 


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo442001j.server", "XxpoShipToResultAMLocal");
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
   * Container's getter for XxpoShipToHeaderPVO1
   */
  public XxpoShipToHeaderPVOImpl getXxpoShipToHeaderPVO1()
  {
    return (XxpoShipToHeaderPVOImpl)findViewObject("XxpoShipToHeaderPVO1");
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
   * Container's getter for XxpoShipToTotalVO1
   */
  public XxpoShipToTotalVOImpl getXxpoShipToTotalVO1()
  {
    return (XxpoShipToTotalVOImpl)findViewObject("XxpoShipToTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToLineVO1
   */
  public XxpoShipToLineVOImpl getXxpoShipToLineVO1()
  {
    return (XxpoShipToLineVOImpl)findViewObject("XxpoShipToLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToResultVO1
   */
  public XxpoShipToResultVOImpl getXxpoShipToResultVO1()
  {
    return (XxpoShipToResultVOImpl)findViewObject("XxpoShipToResultVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToHeaderVO1
   */
  public XxpoShipToHeaderVOImpl getXxpoShipToHeaderVO1()
  {
    return (XxpoShipToHeaderVOImpl)findViewObject("XxpoShipToHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoShipToLinePVO1
   */
  public XxpoShipToLinePVOImpl getXxpoShipToLinePVO1()
  {
    return (XxpoShipToLinePVOImpl)findViewObject("XxpoShipToLinePVO1");
  }
}