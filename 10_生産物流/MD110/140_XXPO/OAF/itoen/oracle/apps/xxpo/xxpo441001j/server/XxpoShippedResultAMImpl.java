/*============================================================================
* �t�@�C���� : XxpoShippedResultAMImpl
* �T�v����   : �o�Ɏ��їv��A�v���P�[�V�������W���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-25 1.0  �R�{���v     �V�K�쐬
* 2008-06-30 1.1  ��r���     �����ύX�v���Ή�#146,#149,ST�s�#248�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;
import itoen.oracle.apps.xxpo.util.server.XxpoProvSearchVOImpl;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

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
 * �o�Ɏ��їv���ʂ̃A�v���P�[�V�������W���[���N���X�ł��B
 * @author  ORACLE �R�{���v
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShippedResultAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedResultAMImpl()
  {
  }

  /***************************************************************************
   * �o�Ɏ��їv���ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeList(
    String exeType
    )
  {
    // �x���˗��v�񌟍�VO
    OAViewObject vo = getXxpoProvSearchVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!vo.isPreparedForExecution())
    {
      vo.setMaxFetchSize(0);
      vo.insertRow(vo.createRow());
      OARow row = (OARow)vo.first();
      row.setNewRowState(OARow.STATUS_INITIALIZED);
      row.setAttribute("RowKey", new Number(1));
      row.setAttribute("ExeType", exeType);
    }
  } // initializeList
  
  /***************************************************************************
   * �o�Ɏ��їv���ʂ̌����������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchList(
    String exeType
    ) throws OAException
  {
    // �x���v�񋤒ʌ���VO�擾
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

    shParams.put("exeType", exeType);

    // �o�Ɏ��ь���VO�擾
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    // ���������s���܂��B
    vo.initQuery(shParams);
  } // doSearchList

  /***************************************************************************
   * �o�Ɏ��їv���ʂ̑S���o�ɏ����O�̖��I���`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkBeforeDecision() throws OAException
  {
    // ���Ɏ��ь���VO�擾
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    
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
      throw new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
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
      throw new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
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
   * �y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   ***************************************************************************
   */
  public void checkBoxOff()
  {
    // �����Ώۂ��擾���܂��B
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);
    // ���I���`�F�b�N���s���܂��B
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
   * �o�Ɏ��їv���ʂ̑S���o�ɏ������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doDecisionList(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // �����Ώۂ��擾
    OAViewObject vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

    // ���I���`�F�b�N
    if ((rows == null) || (rows.length == 0))
    {
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10144);
    } else 
    {
      OARow row = null;
      // �I��`�[loop
      for (int i = 0; i < rows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        // �r���`�F�b�N
        if(chkLockAndExclusive(vo, row))
        {
           // �G���[�`�F�b�N
          if(chkInputAll(vo,row,exceptions))
          {
            // �S���o�ɂ̎��ѓo�^����
            Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
            Date shipDate = (Date)row.getAttribute("ShippedDate");
            if((XxpoUtility.updateOrderExecute(getOADBTransaction(),
                                               orderHeader,
                                               XxpoConstants.REC_TYPE_20,
                                               shipDate)))
            {
              exeFlag = true;
            } else
            {
              // �g�[�N������
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                         "�S������") };
              // �G���[���b�Z�[�W�o��
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN05002, 
                                    tokens);
            }

            // �o�ɏ���
            String requestNo = (String)row.getAttribute("RequestNo");
            XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
            // �G���[���������ꍇ�G���[���X���[���܂��B
            if (exceptions.size() > 0)
            {
              //�g�[�N������
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_CONC_NAME,
                                                         XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
              // �G���[���b�Z�[�W�o��
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxpoConstants.XXPO10024, 
                                    tokens);
            }
          }
        }    
      }
      // �G���[���������ꍇ�G���[���X���[���܂��B
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
      // �X�V�������b�Z�[�W
      if (exeFlag) 
      {
        // �R�~�b�g���s
        XxpoUtility.commit(getOADBTransaction());
        // �Č������s���܂��B
        doSearchList(exeType);
        // �X�V�������b�Z�[�W
        XxcmnUtility.putSuccessMessage(XxpoConstants.TOKEN_NAME_ALL_SHIPPED);
      } else
      {
        // ���[���o�b�N���܂��B
        XxpoUtility.rollBack(getOADBTransaction());
      }
    }
  } // doDecisionList

  /***************************************************************************
   * �˗�No���ƂɑS���o�Ƀ`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkInputAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean retFlag = true;
    
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      // �o�ד��̔N�������߂ɃN���[�Y�����݌ɉ�v���ԔN���̏ꍇ�̓G���[�B
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "ShippedDate",
                                            shippedDate,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10119));
    }

    // ���і����̓`�F�b�N���s���܂��B
    Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
    if(!(XxpoUtility.chkOrderResult(getOADBTransaction(),
                                    orderHeader,XxpoConstants.REC_TYPE_20)))
    {
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
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
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                             vo.getName(),
                                             row.getKey(),
                                             "RequestNo",
                                             requestNo,
                                             XxcmnConstants.APPL_XXPO, 
                                             XxpoConstants.XXPO10202));
    }

    if(exceptions.size() > 0 )
    {
      retFlag = false;
    }
    return retFlag;
  } // chkInputAll

  /***************************************************************************
   * �o�Ɏ��їv���ʂ̎w����̏������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doRcvList(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;

    // �����Ώۂ��擾
    XxpoShippedResultVOImpl vo = getXxpoShippedResultVO1();
    Row[] rows = vo.getFilteredRows("MultiSelect", XxcmnConstants.STRING_Y);

    // ���I���`�F�b�N
    if ((rows == null) || (rows.length == 0))
    {
      //�G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10144);
    } else 
    {
      OARow row = null;
      // �I��`�[loop
      for (int i = 0; i < rows.length; i++) 
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        // �r���`�F�b�N
        if(chkLockAndExclusive(vo, row))
        {
          // �G���[�`�F�b�N
          if(chkRcvAll(vo, row, exceptions))
          {
            // �w����̍X�V����
            Number orderHeader = (Number)row.getAttribute("OrderHeaderId");
            if((updateInstRcvClass(getOADBTransaction(),
                                   orderHeader)))
            {
              exeFlag = true;
            } else
            {
              // �g�[�N������
              MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                         "�w�����") };
              // �G���[���b�Z�[�W�o��
              throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                    XxcmnConstants.XXCMN05002, 
                                    tokens);
            }
          }
        }    
      }
      // �G���[���������ꍇ�G���[���X���[���܂��B
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
      // �X�V�������b�Z�[�W
      if (exeFlag) 
      {
        // �R�~�b�g���s
        XxpoUtility.commit(getOADBTransaction());
        // �Č������s���܂��B
        doSearchList(exeType);
        // �X�V�������b�Z�[�W
        throw new OAException(XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO30042, 
                              null, 
                              OAException.INFORMATION, 
                              null);
      } else
      {
        // ���[���o�b�N���܂��B
        XxpoUtility.rollBack(getOADBTransaction());
      }
    }
  } // doRcvList

  /***************************************************************************
   * �˗�No���ƂɎw����̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @param exceptions - �G���[���b�Z�[�W�i�[�p�z��
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean chkRcvAll(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
    ) throws OAException
  {
    boolean retFlag = true;
    
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N
    Date shippedDate = (Date)row.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      // �o�ד��̔N�������߂ɃN���[�Y�����݌ɉ�v���ԔN���̏ꍇ�̓G���[�B
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "ShippedDate",
                                            shippedDate,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10119));
    }

    // ���z�m��ς݃`�F�b�N
    String fixClass = (String)row.getAttribute("FixClass"); // ���z�m��敪
    if (XxpoConstants.FIX_CLASS_ON.equals(fixClass)) 
    {
      // �G���[���b�Z�[�W�͔����敪���ɕ\��
      Number orderType = (Number)row.getAttribute("OrderTypeId"); // �����敪
      // ���z�m���(1)�̏ꍇ�̓G���[�B
      exceptions.add(new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,
                                            vo.getName(),
                                            row.getKey(),
                                            "OrderTypeId",
                                            orderType,
                                            XxcmnConstants.APPL_XXPO,
                                            XxpoConstants.XXPO10125));
    }

    if(exceptions.size() > 0 )
    {
      retFlag = false;
    }
    return retFlag;
  } // chkRcvAll

  /*****************************************************************************
   * �󒍃w�b�_�A�h�I���̎x���w����̋敪���X�V���܂��B
   * @param trans - �g�����U�N�V����
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   * @throws OAException  - OA��O
   ****************************************************************************/
  public boolean updateInstRcvClass(
    OADBTransaction trans,
    Number orderHeaderId
    ) throws OAException
  {
    boolean retFlag = true;

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN "  );
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");                  // �󒍃w�b�_�A�h�I��
    sb.append("  SET    xoha.shikyu_inst_rcv_class  = '1'  ");            // �x���w����̋敪
    sb.append("        ,xoha.last_updated_by   = FND_GLOBAL.USER_ID  ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date  = SYSDATE             ");  // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login = FND_GLOBAL.LOGIN_ID ");  // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id   = :1;  ");                 // �����w�b�_�A�h�I��ID
    sb.append("END; ");
    
    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = trans.createCallableStatement(sb.toString(),
                                                            OADBTransaction.DEFAULT);
    try
    {
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(1, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
      // PL/SQL���s
      cstmt.execute();
    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      retFlag = false;
    } finally
    {
      try
      {
        // PL/SQL�N���[�Y
        cstmt.close();

      // close���ɗ�O�����������ꍇ 
      } catch(SQLException s)
      {
        retFlag = false;
      }
    }
    return retFlag;
  } // updateInstRcvClass

  /***************************************************************************
   * �o�Ɏ��їv���ʂ̃R�~�b�g�E�Č����������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doCommitList(
    String exeType
    ) throws OAException
  {
    // �R�~�b�g���s
    XxpoUtility.commit(getOADBTransaction());
    // �Č������s���܂��B
    doSearchList(exeType);
    // �X�V�������b�Z�[�W
    throw new OAException(XxcmnConstants.APPL_XXPO,
                          XxpoConstants.XXPO30042,
                          null,
                          OAException.INFORMATION,
                          null);
  } //doCommitList

  /***************************************************************************
   * �o�Ɏ��ѓ��̓w�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   * @param reqNo   - �˗�No
   ***************************************************************************
   */
  public void initializeHdr(
    String exeType,
    String reqNo
    )
  {
    // �x���˗��v�񌟍�VO
    OAViewObject svo = getXxpoProvSearchVO1();
    if (svo.getFetchedRowCount() == 0)
    {
      svo.setMaxFetchSize(0);
      svo.insertRow(svo.createRow());
      OARow srow = (OARow)svo.first();
      srow.setNewRowState(OARow.STATUS_INITIALIZED);
      srow.setAttribute("RowKey", new Number(1));
      srow.setAttribute("ExeType", exeType);
    }
    // �o�Ɏ��ѓ��̓w�b�_PVO
    XxpoShippedMakeHeaderPVOImpl pvo = getXxpoShippedMakeHeaderPVO1();
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
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShippedMakeHeaderVOImpl vo = getXxpoShippedMakeHeaderVO1();
    OARow row = (OARow)vo.first();
    // �X�V�����ڐ���
    handleEventUpdHdr(exeType, prow, row);

    // ���׍s�̌���
    doSearchLine(exeType);

  } // initializeHdr

  /***************************************************************************
   * �o�Ɏ��ѓ��̓w�b�_��ʂ̌����������s�����\�b�h�ł��B
   * @param  reqNo - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchHdr(
    String reqNo
    ) throws OAException
  {
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShippedMakeHeaderVOImpl vo = getXxpoShippedMakeHeaderVO1();
    // ���������s���܂��B
    vo.initQuery(reqNo);
    vo.first();
    // �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // �o�Ɏ��ѓ��̓w�b�_PVO
      XxpoShippedMakeHeaderPVOImpl pvo = getXxpoShippedMakeHeaderPVO1();
      OARow prow = (OARow)pvo.first();
      // �Q�Ƃ̂�
      handleEventAllOffHdr(prow);
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }
  } // doSearchHdr

  /***************************************************************************
     * �o�Ɏ��ѓ��̓w�b�_��ʂ̎��֏������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doNext() throws OAException
  {
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    OAViewObject vo = getXxpoShippedMakeHeaderVO1();
    OARow row   = (OARow)vo.first();
    // ���֏����`�F�b�N
    chkNext(vo, row);
  } // doNext

  /***************************************************************************
   * �o�Ɏ��ѓ��͖��׉�ʂ̏������������s�����\�b�h�ł��B
   * @param exeType - �N���^�C�v
   ***************************************************************************
   */
  public void initializeLine(
    String exeType
    )
  {
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShippedMakeHeaderVOImpl hdrVvo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVvo.first();
    // �o�Ɏ��ѓ��͖���PVO
    XxpoShippedMakeLinePVOImpl pvo = getXxpoShippedMakeLinePVO1();
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
   * �o�Ɏ��ѓ��͖��׉�ʂ̌����������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchLine(
    String exeType
    ) throws OAException
  {
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShippedMakeHeaderVOImpl hdrVo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �󒍃w�b�_�A�h�I��ID���擾���܂��B
    Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID
    // �o�Ɏ��ѓ��̓w�b�_VO�擾
    XxpoShippedMakeLineVOImpl vo = getXxpoShippedMakeLineVO1();
    // ���������s���܂��B
    vo.initQuery(exeType, orderHeaderId);
    vo.first();
    // �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�G���[
    if ((vo == null) || (vo.getFetchedRowCount() == 0)) 
    {
      // �o�Ɏ��ѓ��͖���PVO
      XxpoShippedMakeLinePVOImpl pvo = getXxpoShippedMakeLinePVO1();
      OARow prow = (OARow)pvo.first();
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10500);
    }

    // �o�Ɏ��ѓ��͍��vVO�擾
    XxpoShippedMakeTotalVOImpl totalVo = getXxpoShippedMakeTotalVO1();
    // ���������s���܂��B
    totalVo.initQuery(orderHeaderId);

  } // doSearchLine

  /***************************************************************************
   * �o�Ɏ��э쐬�w�b�_��ʂ̍��ڂ�S��FALSE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOnHdr(OARow prow)
  {
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.FALSE); // �o�ɓ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.FALSE); // �E�v
    prow.setAttribute("RcvClassReadOnly"             , Boolean.FALSE); // �w�����

  } // handleEventAllOnHdr

  /***************************************************************************
   * �o�Ɏ��э쐬�w�b�_��ʂ̍��ڂ�S��TRUE�ɂ��郁�\�b�h�ł��B
   * @param prow    - PVO�s�N���X
   ***************************************************************************
   */
  public void handleEventAllOffHdr(OARow prow)
  {
    prow.setAttribute("ShippedDateReadOnly"          , Boolean.TRUE); // �o�ɓ�
    prow.setAttribute("ShippingInstructionsReadOnly" , Boolean.TRUE); // �E�v
    prow.setAttribute("RcvClassReadOnly"             , Boolean.TRUE); // �w�����

  } // handleEventAllOffHdr

  /***************************************************************************
   * �o�Ɏ��ѓ��̓w�b�_��ʂ̍X�V���̍��ڐ��䏈�����s�����\�b�h�ł��B
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
        // �^���敪���uON�v�̏ꍇ�͏o�ɓ�����s��
        if (XxcmnConstants.STRING_ONE.equals(freightClass)) 
        {
          prow.setAttribute("ShippedDateReadOnly", Boolean.TRUE);  
        }
        
      } else
      {
        // �Q�Ƃ̂�
        handleEventAllOffHdr(prow);
      }
    }
  } //  handleEventUpdHdr

  /***************************************************************************
   * �o�Ɏ��ѓ��͖��׉�ʂ̓K�p�������s�����\�b�h�ł��B
   * @param  exeType - �N���^�C�v
   * @return HashMap - �߂�l�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap doApply(
    String exeType
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    boolean exeFlag = false;
    // �o�Ɏ��уw�b�_VO�擾
    XxpoShippedMakeHeaderVOImpl hdrVo = getXxpoShippedMakeHeaderVO1();
    OARow hdrRow = (OARow)hdrVo.first();
    // �`�F�b�N����
    // �݌ɉ�v���ԃN���[�Y�`�F�b�N���s���܂��B
    Date shippedDate = (Date)hdrRow.getAttribute("ShippedDate"); // �o�ɓ�
    if (XxpoUtility.chkStockClose(getOADBTransaction(),
                                  shippedDate))
    {
      exceptions.add( new OAAttrValException(OAAttrValException.TYP_VIEW_OBJECT,          
                                             hdrVo.getName(),
                                             hdrRow.getKey(),
                                             "ShippedDate",
                                             shippedDate,
                                             XxcmnConstants.APPL_XXPO, 
                                             XxpoConstants.XXPO10119));
    }

    // �r���`�F�b�N
    String reqNo   = (String)hdrRow.getAttribute("RequestNo"); // �˗�No
    String tokenName = null;
    chkLockAndExclusive(hdrVo, hdrRow);
    tokenName = XxpoConstants.TOKEN_NAME_UPD;

    // �ǉ��E�X�V����
    if (doExecute(hdrRow)) 
    {
      // �R�~�b�g����
      XxpoUtility.commit(getOADBTransaction());
      if (XxpoConstants.TOKEN_NAME_UPD.equals(tokenName)) 
      {
        // ������
        initializeHdr(exeType, reqNo);
        initializeLine(exeType);
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
   * ���փ{�^���������̃`�F�b�N���s�����\�b�h�ł��B
   * @param vo - �r���[�I�u�W�F�N�g
   * @param row - �s�I�u�W�F�N�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkNext(
    OAViewObject vo,
    OARow row
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(10);
    // �o�ɓ�
    Date shippedDate = (Date)row.getAttribute("ShippedDate");
    // ���ɓ�
    Date arrivalDate = (Date)row.getAttribute("ArrivalDate");
    // �V�X�e�����t���擾
    Date currentDate = getOADBTransaction().getCurrentDBDate();
    // �K�{�`�F�b�N
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
    // �o�ɓ����������̏ꍇ
    } else if (!XxcmnUtility.chkCompareDate(2, currentDate, (Date)shippedDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10244));
    // �o�ɓ������ɓ��̏ꍇ
    } else if (XxcmnUtility.chkCompareDate(1, shippedDate, arrivalDate)) 
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            vo.getName(),
                            row.getKey(),
                            "ShippedDate",
                            shippedDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10118));

    // �݌ɉ�v���ԃN���[�Y�`�F�b�N
    } else if (XxpoUtility.chkStockClose(getOADBTransaction(), shippedDate))
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
    // �G���[���������ꍇ�G���[���X���[���܂��B
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chkNext

  /***************************************************************************
   * �X�V�����̒ǉ��E�X�V�������s�����\�b�h�ł��B
   * @param hdrRow - �w�b�_�s�I�u�W�F�N�g
   * @return boolean - �߂�l�Q
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean doExecute(
    OARow hdrRow
    ) throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // �o�Ɏ��і���VO
    XxpoShippedMakeLineVOImpl vo = getXxpoShippedMakeLineVO1();
    boolean lineExeFlag = false;
    boolean hdrExeFlag  = false;
    boolean shippedExeFlag  = false;

    // �w�b�_�X�V����
    hdrExeFlag = executeOrderHeader(hdrRow);

    // ���׍X�V�s�擾
    Row[] lineRows = vo.getFilteredRows("RecordType", XxcmnConstants.STRING_N);
    if ((lineRows != null) || (lineRows.length > 0)) 
    {
      OARow lineRow = null;
      for (int i = 0; i < lineRows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        lineRow = (OARow)lineRows[i];

        // ���׍X�V����
        if (executeOrderLine(hdrRow, lineRow)) 
        {
          // ���׎��s�t���O��true�ɕύX
          lineExeFlag = true;
        }
      }
    }

    // �o�ɏ���
    // �X�e�[�^�X���u�o�׎��ьv��ρv�ŏo�ɓ����ύX����Ă����ꍇ
    if ( XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK)
     && !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"), hdrRow.getAttribute("DbShippedDate")))
    {

      // �o�ɏ���
      String requestNo = (String)hdrRow.getAttribute("RequestNo");
      XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
      shippedExeFlag = true;
      // �G���[���������ꍇ�G���[���X���[���܂��B
      if (exceptions.size() > 0)
      {
        //�g�[�N������
        MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_CONC_NAME,
                                                   XxwshConstants.TOKEN_NAME_PGM_NAME_420001C) };
        // �G���[���b�Z�[�W�o��
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxpoConstants.XXPO10024, 
                              tokens);
      }
    }
    
    if (hdrExeFlag || lineExeFlag || shippedExeFlag) 
    {
      return true;
    } else
    {
      return false;
    }
  } // doExecute

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���̃f�[�^���X�V���܂��B
   * @param hdrRow - �X�V�Ώۍs
   * @return boolean - �X�V���s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean executeOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName      = "executeOrderHeader";
    boolean hdrExeFlag  = false;

    // �o�ɓ��A�E�v�A�w����̂��ύX���ꂽ�ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),          
                               hdrRow.getAttribute("DbShippedDate")) 
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippingInstructions"),           
                               hdrRow.getAttribute("DbShippingInstructions"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("RcvClass"),                       
                               hdrRow.getAttribute("DbRcvClass")))
    {
      // �o�ɓ����ύX����Ă����ꍇ
      if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"),            
                                 hdrRow.getAttribute("DbShippedDate")))
      {
        // �X�e�[�^�X���u�o�׎��ьv��ρv�̏ꍇ
        if (XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK))
        {
          // �w�b�_���ѕύX����
          orderHeaderInsUpd(hdrRow);
          hdrExeFlag  = true;
        } else 
        {
          // �w�b�_�̍X�V
          updateOrderHeader(hdrRow);
          // �ړ����b�g�ڍׂ̍X�V
          updateMovLotDetails(hdrRow);
          hdrExeFlag  = true;
        }
      } else
      {
        // �w�b�_�̍X�V
        updateOrderHeader(hdrRow);
        hdrExeFlag  = true;
      }
    }
    return hdrExeFlag;
  } // executeOrderHeader

  /***************************************************************************
   * �󒍖��׃A�h�I���̃f�[�^���X�V���܂��B
   * @param hdrRow  - �X�V�Ώۃw�b�_�s
   * @param lineRow - �X�V�Ώۖ��׍s
   * @return boolean - �X�V���s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public boolean executeOrderLine(
    OARow hdrRow,
    OARow lineRow
    ) throws OAException
  {
    String apiName      = "executeOrderLine";
    boolean lineExeFlag = false;

    // �X�e�[�^�X���u�o�׎��ьv��ρv�ŏo�ɓ����ύX����Ă����ꍇ
    if ( XxcmnUtility.isEquals(hdrRow.getAttribute("TransStatus"), XxpoConstants.PROV_STATUS_SJK)
     && !XxcmnUtility.isEquals(hdrRow.getAttribute("ShippedDate"), hdrRow.getAttribute("DbShippedDate")))
    {

      // �󒍖��׃A�h�I��ID�̃V�[�P���X�擾
      Number newOrderLineId = getOrderLineId(getOADBTransaction());

      // ���׎��ѕύX����(�V�K�󒍖��׍쐬)
      insertOrderLine(lineRow, newOrderLineId);
      // ���׎��ѕύX����(�V�K�ړ����b�g���׍쐬)
      insertMovLotDetails(hdrRow, lineRow, newOrderLineId);
      lineExeFlag = true;
    } else
    {
      // ���ׂ̈ȉ��̍��ڂ��X�V���ꂽ�ꍇ
      // �E���l
      if (!XxcmnUtility.isEquals(lineRow.getAttribute("LineDescription"), 
                                 lineRow.getAttribute("DbLineDescription")))
      {
        // ���׍s�̍X�V
        updateOrderLine(lineRow);
        lineExeFlag = true;
      }
    }
    return lineExeFlag;
  } // executeOrderLine 

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���̎��ѕύX�������s���܂��B
   * @param updRow - �X�V�Ώۍs
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void orderHeaderInsUpd(
    OARow updRow
    ) throws OAException
  {
    String apiName = "orderHeaderInsUpd";
    
    // �V�w�b�_�̍쐬
    insertOrderHeader(updRow);
    // ���w�b�_�̍X�V
    updateOldOrderHeader(updRow);

  } // orderHeaderInsUpd

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void insertOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "insertOrderHeader";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_headers_all(");
    sb.append("    order_header_id                  "); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,order_type_id                    "); // �󒍃^�C�vID
    sb.append("   ,organization_id                  "); // �g�DID
    sb.append("   ,latest_external_flag             "); // �ŐV�t���O
    sb.append("   ,ordered_date                     "); // �󒍓�
    sb.append("   ,customer_id                      "); // �ڋqID
    sb.append("   ,customer_code                    "); // �ڋq
    sb.append("   ,deliver_to_id                    "); // �o�א�ID
    sb.append("   ,deliver_to                       "); // �o�א�
    sb.append("   ,shipping_instructions            "); // �o�׎w��
    sb.append("   ,career_id                        "); // �^���Ǝ�ID
    sb.append("   ,freight_carrier_code             "); // �^���Ǝ�
    sb.append("   ,shipping_method_code             "); // �z���敪
    sb.append("   ,cust_po_number                   "); // �ڋq����
    sb.append("   ,price_list_id                    "); // ���i�\
    sb.append("   ,request_no                       "); // �˗�No
    sb.append("   ,req_status                       "); // �X�e�[�^�X
    sb.append("   ,delivery_no                      "); // �z��No
    sb.append("   ,prev_delivery_no                 "); // �O��z��No
    sb.append("   ,schedule_ship_date               "); // �o�ח\���
    sb.append("   ,schedule_arrival_date            "); // ���ח\���
    sb.append("   ,mixed_no                         "); // ���ڌ�No
    sb.append("   ,collected_pallet_qty             "); // �p���b�g�������
    sb.append("   ,confirm_request_class            "); // �����S���m�F�˗��敪
    sb.append("   ,freight_charge_class             "); // �^���敪
    sb.append("   ,shikyu_instruction_class         "); // �x���o�Ɏw���敪
    sb.append("   ,shikyu_inst_rcv_class            "); // �x���w����̋敪
    sb.append("   ,amount_fix_class                 "); // �L�����z�m��敪
    sb.append("   ,takeback_class                   "); // ����敪
    sb.append("   ,deliver_from_id                  "); // �o�׌�ID
    sb.append("   ,deliver_from                     "); // �o�׌��ۊǏꏊ
    sb.append("   ,head_sales_branch                "); // �Ǌ����_
    sb.append("   ,input_sales_branch               "); // ���͋��_
    sb.append("   ,po_no                            "); // ����No
    sb.append("   ,prod_class                       "); // ���i�敪
    sb.append("   ,item_class                       "); // �i�ڋ敪
    sb.append("   ,no_cont_freight_class            "); // �_��O�^���敪
    sb.append("   ,arrival_time_from                "); // ���׎���FROM
    sb.append("   ,arrival_time_to                  "); // ���׎���TO
    sb.append("   ,designated_item_id               "); // �����i��ID
    sb.append("   ,designated_item_code             "); // �����i��
    sb.append("   ,designated_production_date       "); // ������
    sb.append("   ,designated_branch_no             "); // �����}��
    sb.append("   ,slip_number                      "); // �����No
    sb.append("   ,sum_quantity                     "); // ���v����
    sb.append("   ,small_quantity                   "); // ������
    sb.append("   ,label_quantity                   "); // ���x������
    sb.append("   ,loading_efficiency_weight        "); // �d�ʐύڌ���
    sb.append("   ,loading_efficiency_capacity      "); // �e�ϐύڌ���
    sb.append("   ,based_weight                     "); // ��{�d��
    sb.append("   ,based_capacity                   "); // ��{�e��
    sb.append("   ,sum_weight                       "); // �ύڏd�ʍ��v
    sb.append("   ,sum_capacity                     "); // �ύڗe�ύ��v
    sb.append("   ,mixed_ratio                      "); // ���ڗ�
    sb.append("   ,pallet_sum_quantity              "); // �p���b�g���v����
    sb.append("   ,real_pallet_quantity             "); // �p���b�g���і���
    sb.append("   ,sum_pallet_weight                "); // ���v�p���b�g�d��
    sb.append("   ,order_source_ref                 "); // �󒍃\�[�X�Q��
    sb.append("   ,result_freight_carrier_id        "); // �^���Ǝ�_����ID
    sb.append("   ,result_freight_carrier_code      "); // �^���Ǝ�_����
    sb.append("   ,result_shipping_method_code      "); // �z���敪_����
    sb.append("   ,result_deliver_to_id             "); // �o�א�_����ID
    sb.append("   ,result_deliver_to                "); // �o�א�_����
    sb.append("   ,shipped_date                     "); // �o�ד�
    sb.append("   ,arrival_date                     "); // ���ד�
    sb.append("   ,weight_capacity_class            "); // �d�ʗe�ϋ敪
    sb.append("   ,actual_confirm_class             "); // ���ьv��ϋ敪
    sb.append("   ,notif_status                     "); // �ʒm�X�e�[�^�X
    sb.append("   ,prev_notif_status                "); // �O��ʒm�X�e�[�^�X
    sb.append("   ,notif_date                       "); // �m��ʒm���{����
    sb.append("   ,new_modify_flg                   "); // �V�K�C���t���O
    sb.append("   ,process_status                   "); // �����o�߃X�e�[�^�X
    sb.append("   ,performance_management_dept      "); // ���ъǗ�����
    sb.append("   ,instruction_dept                 "); // �w������
    sb.append("   ,transfer_location_id             "); // �U�֐�ID
    sb.append("   ,transfer_location_code           "); // �U�֐�
    sb.append("   ,mixed_sign                       "); // ���ڋL��
    sb.append("   ,screen_update_date               "); // ��ʍX�V����
    sb.append("   ,screen_update_by                 "); // ��ʍX�V��
    sb.append("   ,tightening_date                  "); // �o�׈˗����ߓ���
    sb.append("   ,vendor_id                        "); // �����ID
    sb.append("   ,vendor_code                      "); // �����
    sb.append("   ,vendor_site_id                   "); // �����T�C�gID
    sb.append("   ,vendor_site_code                 "); // �����T�C�g
    sb.append("   ,registered_sequence              "); // �o�^����
    sb.append("   ,tightening_program_id            "); // ���߃R���J�����gID
    sb.append("   ,corrected_tighten_class          "); // ���ߌ�C���敪
    sb.append("   ,created_by                       "); // �쐬��
    sb.append("   ,creation_date                    "); // �쐬��
    sb.append("   ,last_updated_by                  "); // �ŏI�X�V��
    sb.append("   ,last_update_date                 "); // �ŏI�X�V��
    sb.append("   ,last_update_login )              "); // �ŏI�X�V���O�C��
    sb.append("  SELECT ");
    sb.append("    :1                               "); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,xoha.order_type_id               "); // �󒍃^�C�vID
    sb.append("   ,xoha.organization_id             "); // �g�DID
    sb.append("   ,'Y'                              "); // �ŐV�t���O
    sb.append("   ,xoha.ordered_date                "); // �󒍓�
    sb.append("   ,xoha.customer_id                 "); // �ڋqID
    sb.append("   ,xoha.customer_code               "); // �ڋq
    sb.append("   ,xoha.deliver_to_id               "); // �o�א�ID
    sb.append("   ,xoha.deliver_to                  "); // �o�א�
    sb.append("   ,:2                               "); // �o�׎w��
    sb.append("   ,xoha.career_id                   "); // �^���Ǝ�ID
    sb.append("   ,xoha.freight_carrier_code        "); // �^���Ǝ�
    sb.append("   ,xoha.shipping_method_code        "); // �z���敪
    sb.append("   ,xoha.cust_po_number              "); // �ڋq����
    sb.append("   ,xoha.price_list_id               "); // ���i�\
    sb.append("   ,xoha.request_no                  "); // �˗�No
    sb.append("   ,xoha.req_status                  "); // �X�e�[�^�X
    sb.append("   ,xoha.delivery_no                 "); // �z��No
    sb.append("   ,xoha.prev_delivery_no            "); // �O��z��No
    sb.append("   ,xoha.schedule_ship_date          "); // �o�ח\���
    sb.append("   ,xoha.schedule_arrival_date       "); // ���ח\���
    sb.append("   ,xoha.mixed_no                    "); // ���ڌ�No
    sb.append("   ,xoha.collected_pallet_qty        "); // �p���b�g�������
    sb.append("   ,xoha.confirm_request_class       "); // �����S���m�F�˗��敪
    sb.append("   ,xoha.freight_charge_class        "); // �^���敪
    sb.append("   ,xoha.shikyu_instruction_class    "); // �x���o�Ɏw���敪
    sb.append("   ,:3                               "); // �x���w����̋敪
    sb.append("   ,xoha.amount_fix_class            "); // �L�����z�m��敪
    sb.append("   ,xoha.takeback_class              "); // ����敪
    sb.append("   ,xoha.deliver_from_id             "); // �o�׌�ID
    sb.append("   ,xoha.deliver_from                "); // �o�׌��ۊǏꏊ
    sb.append("   ,xoha.head_sales_branch           "); // �Ǌ����_
    sb.append("   ,xoha.input_sales_branch          "); // ���͋��_
    sb.append("   ,xoha.po_no                       "); // ����No
    sb.append("   ,xoha.prod_class                  "); // ���i�敪
    sb.append("   ,xoha.item_class                  "); // �i�ڋ敪
    sb.append("   ,xoha.no_cont_freight_class       "); // �_��O�^���敪
    sb.append("   ,xoha.arrival_time_from           "); // ���׎���FROM
    sb.append("   ,xoha.arrival_time_to             "); // ���׎���TO
    sb.append("   ,xoha.designated_item_id          "); // �����i��ID
    sb.append("   ,xoha.designated_item_code        "); // �����i��
    sb.append("   ,xoha.designated_production_date  "); // ������
    sb.append("   ,xoha.designated_branch_no        "); // �����}��
    sb.append("   ,xoha.slip_number                 "); // �����No
    sb.append("   ,xoha.sum_quantity                "); // ���v����
    sb.append("   ,xoha.small_quantity              "); // ������
    sb.append("   ,xoha.label_quantity              "); // ���x������
    sb.append("   ,xoha.loading_efficiency_weight   "); // �d�ʐύڌ���
    sb.append("   ,xoha.loading_efficiency_capacity "); // �e�ϐύڌ���
    sb.append("   ,xoha.based_weight                "); // ��{�d��
    sb.append("   ,xoha.based_capacity              "); // ��{�e��
    sb.append("   ,xoha.sum_weight                  "); // �ύڏd�ʍ��v
    sb.append("   ,xoha.sum_capacity                "); // �ύڗe�ύ��v
    sb.append("   ,xoha.mixed_ratio                 "); // ���ڗ�
    sb.append("   ,xoha.pallet_sum_quantity         "); // �p���b�g���v����
    sb.append("   ,xoha.real_pallet_quantity        "); // �p���b�g���і���
    sb.append("   ,xoha.sum_pallet_weight           "); // ���v�p���b�g�d��
    sb.append("   ,xoha.order_source_ref            "); // �󒍃\�[�X�Q��
    sb.append("   ,xoha.result_freight_carrier_id   "); // �^���Ǝ�_����ID
    sb.append("   ,xoha.result_freight_carrier_code "); // �^���Ǝ�_����
    sb.append("   ,xoha.result_shipping_method_code "); // �z���敪_����
    sb.append("   ,xoha.result_deliver_to_id        "); // �o�א�_����ID
    sb.append("   ,xoha.result_deliver_to           "); // �o�א�_����
    sb.append("   ,:4                               "); // �o�ד�
    sb.append("   ,xoha.arrival_date                "); // ���ד�
    sb.append("   ,xoha.weight_capacity_class       "); // �d�ʗe�ϋ敪
    sb.append("   ,'N'                              "); // ���ьv��ϋ敪
    sb.append("   ,xoha.notif_status                "); // �ʒm�X�e�[�^�X
    sb.append("   ,xoha.prev_notif_status           "); // �O��ʒm�X�e�[�^�X
    sb.append("   ,xoha.notif_date                  "); // �m��ʒm���{����
    sb.append("   ,xoha.new_modify_flg              "); // �V�K�C���t���O
    sb.append("   ,xoha.process_status              "); // �����o�߃X�e�[�^�X
    sb.append("   ,xoha.performance_management_dept "); // ���ъǗ�����
    sb.append("   ,xoha.instruction_dept            "); // �w������
    sb.append("   ,xoha.transfer_location_id        "); // �U�֐�ID
    sb.append("   ,xoha.transfer_location_code      "); // �U�֐�
    sb.append("   ,xoha.mixed_sign                  "); // ���ڋL��
    sb.append("   ,xoha.screen_update_date          "); // ��ʍX�V����
    sb.append("   ,xoha.screen_update_by            "); // ��ʍX�V��
    sb.append("   ,xoha.tightening_date             "); // �o�׈˗����ߓ���
    sb.append("   ,xoha.vendor_id                   "); // �����ID
    sb.append("   ,xoha.vendor_code                 "); // �����
    sb.append("   ,xoha.vendor_site_id              "); // �����T�C�gID
    sb.append("   ,xoha.vendor_site_code            "); // �����T�C�g
    sb.append("   ,xoha.registered_sequence         "); // �o�^����
    sb.append("   ,xoha.tightening_program_id       "); // ���߃R���J�����gID
    sb.append("   ,xoha.corrected_tighten_class     "); // ���ߌ�C���敪
    sb.append("   ,FND_GLOBAL.USER_ID               "); // �쐬��
    sb.append("   ,SYSDATE                          "); // �쐬��
    sb.append("   ,FND_GLOBAL.USER_ID               "); // �ŏI�X�V��
    sb.append("   ,SYSDATE                          "); // �ŏI�X�V��
    sb.append("   ,FND_GLOBAL.LOGIN_ID              "); // �ŏI�X�V���O�C��
    sb.append("  FROM  xxwsh_order_headers_all xoha "); // �󒍃w�b�_�A�h�I��
    sb.append("  WHERE xoha.order_header_id = :5 ;  "); // �󒍃w�b�_�A�h�I��ID(����)
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �󒍃w�b�_�A�h�I��ID�̃V�[�P���X�擾
      Number newOrderHeaderId = XxpoUtility.getOrderHeaderId(getOADBTransaction());

      // �����擾
      String shippingInstructions  = (String)hdrRow.getAttribute("ShippingInstructions"); // �o�׎w��
      String shikyuInstRcvClass    = (String)hdrRow.getAttribute("RcvClass");             // �x���w����̋敪
      Date   shippedDate           = (Date)hdrRow.getAttribute("ShippedDate");            // �o�ד�
      Number oldOrderHeaderId      = (Number)hdrRow.getAttribute("OrderHeaderId");        // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(newOrderHeaderId));                         // �󒍃w�b�_�A�h�I��ID
      cstmt.setString(i++, shippingInstructions);                                         // �o�׎w��
      cstmt.setString(i++, shikyuInstRcvClass);                                           // �x���w����̋敪
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));                            // �o�ד�
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderHeaderId));                         // �󒍃w�b�_�A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderHeader 

  /***************************************************************************
   * ���󒍃w�b�_�A�h�I���̃f�[�^���X�V���܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void updateOldOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateOldOrderHeader";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET   xoha.latest_external_flag = 'N' " );                // �ŐV�t���O
    sb.append("       ,xoha.last_updated_by      = FND_GLOBAL.USER_ID  "); // �ŏI�X�V��
    sb.append("       ,xoha.last_update_date     = SYSDATE ");             // �ŏI�X�V��
    sb.append("       ,xoha.last_update_login    = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE xoha.order_header_id      = :1 ;                "); // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number orderHeaderId = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOldOrderHeader 

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���̃f�[�^���X�V���܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void updateOrderHeader(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateOrderHeader";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_headers_all xoha ");
    sb.append("  SET    xoha.shipped_date          = :1 ");                  // �o�ד�
    sb.append("        ,xoha.shipping_instructions = :2 ");                  // �o�׎w��
    sb.append("        ,xoha.shikyu_inst_rcv_class = :3 ");                  // �x���w����̋敪
    sb.append("        ,xoha.result_freight_carrier_id   = NVL(xoha.result_freight_carrier_id, xoha.career_id) " );              // �^���Ǝ�_����ID
    sb.append("        ,xoha.result_freight_carrier_code = NVL(xoha.result_freight_carrier_code, xoha.freight_carrier_code) " ); // �^���Ǝ�_����
    sb.append("        ,xoha.result_shipping_method_code = NVL(xoha.result_shipping_method_code, xoha.shipping_method_code) " ); // �z���敪_����
    sb.append("        ,xoha.last_updated_by       = FND_GLOBAL.USER_ID  "); // �ŏI�X�V��
    sb.append("        ,xoha.last_update_date      = SYSDATE ");             // �ŏI�X�V��
    sb.append("        ,xoha.last_update_login     = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xoha.order_header_id       = :4 ;                "); // �󒍃w�b�_�A�h�I��ID
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Date   shippedDate          = (Date)hdrRow.getAttribute("ShippedDate");            // �o�ד�
      String shippingInstructions = (String)hdrRow.getAttribute("ShippingInstructions"); // �o�׎w��
      String shikyuInstRcvClass   = (String)hdrRow.getAttribute("RcvClass");             // �x���w����̋敪
      Number orderHeaderId        = (Number)hdrRow.getAttribute("OrderHeaderId");        // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(i++, XxcmnUtility.dateValue(shippedDate));                           // �o�ד�
      cstmt.setString(i++, shippingInstructions);                                        // �o�׎w��
      cstmt.setString(i++, shikyuInstRcvClass);                                          // �x���w����̋敪
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId));                           // �󒍃w�b�_�A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderHeader 

  /***************************************************************************
   * �ړ����b�g�ڍׂ̃f�[�^���X�V���܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void updateMovLotDetails(
    OARow hdrRow
    ) throws OAException
  {
    String apiName = "updateMovLotDetails";

    // PL/SQL�̍쐬���s���܂�
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
    sb.append("  AND   xmld.record_type_code   = '20'  "); // ���R�[�h�^�C�v�F�o��
    sb.append("  AND   xmld.document_type_code = '30'; "); // �����^�C�v�F�x���w��
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Date   actualDate     = (Date)hdrRow.getAttribute("ShippedDate");     // �o�ד�
      Number orderHeaderId  = (Number)hdrRow.getAttribute("OrderHeaderId"); // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));  // �o�ד�
      cstmt.setInt(i++, XxcmnUtility.intValue(orderHeaderId)); // �󒍃w�b�_�A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateMovLotDetails 

  /***************************************************************************
   * �󒍖��׃A�h�I���Ƀf�[�^��ǉ����܂��B
   * @param lineRow - ���׍s
   * @param newOrderLineID   - �󒍖��׃A�h�I��ID(�V�K�̔�)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void insertOrderLine(
    OARow lineRow,
    Number newOrderLineID
    ) throws OAException
  {
    String apiName = "insertOrderLine";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxwsh_order_lines_all(");
    sb.append("    order_line_id                   "); // �󒍖��׃A�h�I��ID
    sb.append("   ,order_header_id                 "); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,order_line_number               "); // ���הԍ�
    sb.append("   ,request_no                      "); // �˗�No
    sb.append("   ,shipping_inventory_item_id      "); // �o�וi��ID
    sb.append("   ,shipping_item_code              "); // �o�וi��
    sb.append("   ,quantity                        "); // ����
    sb.append("   ,uom_code                        "); // �P��
    sb.append("   ,unit_price                      "); // �P��
    sb.append("   ,shipped_quantity                "); // �o�׎��ѐ���
    sb.append("   ,designated_production_date      "); // �w�萻����
    sb.append("   ,based_request_quantity          "); // ���_�˗�����
    sb.append("   ,request_item_id                 "); // �˗��i��ID
    sb.append("   ,request_item_code               "); // �˗��i��
    sb.append("   ,ship_to_quantity                "); // ���Ɏ��ѐ���
    sb.append("   ,futai_code                      "); // �t�уR�[�h
    sb.append("   ,designated_date                 "); // �w����t�i���[�t�j
    sb.append("   ,move_number                     "); // �ړ�No
    sb.append("   ,po_number                       "); // ����No
    sb.append("   ,cust_po_number                  "); // �ڋq����
    sb.append("   ,pallet_quantity                 "); // �p���b�g��
    sb.append("   ,layer_quantity                  "); // �i��
    sb.append("   ,case_quantity                   "); // �P�[�X��
    sb.append("   ,weight                          "); // �d��
    sb.append("   ,capacity                        "); // �e��
    sb.append("   ,pallet_qty                      "); // �p���b�g����
    sb.append("   ,pallet_weight                   "); // �p���b�g�d��
    sb.append("   ,reserved_quantity               "); // ������
    sb.append("   ,automanual_reserve_class        "); // �����蓮�����敪
    sb.append("   ,delete_flag                     "); // �폜�t���O
    sb.append("   ,warning_class                   "); // �x���敪
    sb.append("   ,warning_date                    "); // �x�����t
    sb.append("   ,line_description                "); // �E�v
    sb.append("   ,rm_if_flg                       "); // �q�֕ԕi�C���^�t�F�[�X�σt���O
    sb.append("   ,shipping_request_if_flg         "); // �o�׈˗��C���^�t�F�[�X�σt���O
    sb.append("   ,shipping_result_if_flg          "); // �o�׎��уC���^�t�F�[�X�σt���O
    sb.append("   ,created_by                      "); // �쐬��
    sb.append("   ,creation_date                   "); // �쐬��
    sb.append("   ,last_updated_by                 "); // �ŏI�X�V��
    sb.append("   ,last_update_date                "); // �ŏI�X�V��
    sb.append("   ,last_update_login )             "); // �ŏI�X�V���O�C��
    sb.append("  SELECT ");
    sb.append("    :1                              "); // �󒍖��׃A�h�I��ID
    sb.append("   ,xohan.order_header_id           "); // �󒍃w�b�_�A�h�I��ID
    sb.append("   ,xola.order_line_number          "); // ���הԍ�
    sb.append("   ,xola.request_no                 "); // �˗�No
    sb.append("   ,xola.shipping_inventory_item_id "); // �o�וi��ID
    sb.append("   ,xola.shipping_item_code         "); // �o�וi��
    sb.append("   ,xola.quantity                   "); // ����
    sb.append("   ,xola.uom_code                   "); // �P��
    sb.append("   ,xola.unit_price                 "); // �P��
    sb.append("   ,xola.shipped_quantity           "); // �o�׎��ѐ���
    sb.append("   ,xola.designated_production_date "); // �w�萻����
    sb.append("   ,xola.based_request_quantity     "); // ���_�˗�����
    sb.append("   ,xola.request_item_id            "); // �˗��i��ID
    sb.append("   ,xola.request_item_code          "); // �˗��i��
    sb.append("   ,xola.ship_to_quantity           "); // ���Ɏ��ѐ���
    sb.append("   ,xola.futai_code                 "); // �t�уR�[�h
    sb.append("   ,xola.designated_date            "); // �w����t�i���[�t�j
    sb.append("   ,xola.move_number                "); // �ړ�No
    sb.append("   ,xola.po_number                  "); // ����No
    sb.append("   ,xola.cust_po_number             "); // �ڋq����
    sb.append("   ,xola.pallet_quantity            "); // �p���b�g��
    sb.append("   ,xola.layer_quantity             "); // �i��
    sb.append("   ,xola.case_quantity              "); // �P�[�X��
    sb.append("   ,xola.weight                     "); // �d��
    sb.append("   ,xola.capacity                   "); // �e��
    sb.append("   ,xola.pallet_qty                 "); // �p���b�g����
    sb.append("   ,xola.pallet_weight              "); // �p���b�g�d��
    sb.append("   ,xola.reserved_quantity          "); // ������
    sb.append("   ,xola.automanual_reserve_class   "); // �����蓮�����敪
    sb.append("   ,xola.delete_flag                "); // �폜�t���O
    sb.append("   ,xola.warning_class              "); // �x���敪
    sb.append("   ,xola.warning_date               "); // �x�����t
    sb.append("   ,:2                              "); // �E�v
    sb.append("   ,xola.rm_if_flg                  "); // �q�֕ԕi�C���^�t�F�[�X�σt���O
    sb.append("   ,xola.shipping_request_if_flg    "); // �o�׈˗��C���^�t�F�[�X�σt���O
    sb.append("   ,xola.shipping_result_if_flg     "); // �o�׎��уC���^�t�F�[�X�σt���O
    sb.append("   ,FND_GLOBAL.USER_ID              "); // �쐬��
    sb.append("   ,SYSDATE                         "); // �쐬��
    sb.append("   ,FND_GLOBAL.USER_ID              "); // �ŏI�X�V��
    sb.append("   ,SYSDATE                         "); // �ŏI�X�V��
    sb.append("   ,FND_GLOBAL.LOGIN_ID             "); // �ŏI�X�V���O�C��
    sb.append("  FROM  xxwsh_order_lines_all  xola "); // �󒍖��׃A�h�I��
    sb.append("       ,xxwsh_order_headers_all xohao "); // �󒍃w�b�_�A�h�I��(����)
    sb.append("       ,xxwsh_order_headers_all xohan "); // �󒍃w�b�_�A�h�I��(�V�K)
    sb.append("  WHERE xola.order_line_id   = :3   "); // �󒍖��׃A�h�I��ID(����)
    sb.append("  AND   xola.order_header_id = :4   "); // �󒍃w�b�_�A�h�I��ID(����)
    sb.append("  AND   xohao.order_header_id = xola.order_header_id   "); // �󒍃w�b�_�A�h�I��(����)���擾
    sb.append("  AND   xohan.request_no      = xohao.request_no   ");     // �󒍃w�b�_�A�h�I��(����)�̈˗�No�Ŏ󒍃w�b�_�A�h�I��(�V�K)���擾
    sb.append("  AND   xohan.latest_external_flag = 'Y' ; ");             // �ŐV�t���O��'Y'�̃f�[�^
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number newOrderLineId    = (Number)newOrderLineID;                          // �󒍖��׃A�h�I��ID
      String lineDescription   = (String)lineRow.getAttribute("LineDescription"); // �E�v
      Number oldOrderLineId    = (Number)lineRow.getAttribute("OrderLineId");     // �󒍖��׃A�h�I��ID
      Number oldOrderHeaderId  = (Number)lineRow.getAttribute("OrderHeaderId");   // �󒍃w�b�_�A�h�I��ID

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(newOrderLineId));   // �󒍖��׃A�h�I��ID
      cstmt.setString(i++, lineDescription);                      // �E�v
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderLineId));   // �󒍖��׃A�h�I��ID
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderHeaderId)); // �󒍃w�b�_�A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertOrderLine 

  /***************************************************************************
   * �ړ����b�g���ׂɃf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @param lineRow - ���׍s
   * @param newOrderLineID - ����ID(�V�K�̔�)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void insertMovLotDetails(
    OARow hdrRow,
    OARow lineRow,
    Number newOrderLineID
    ) throws OAException
  {
    String apiName      = "insertMovLotDetails";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  INSERT INTO xxinv_mov_lot_details                            "); // �ړ����b�g�ڍ�
    sb.append("            ( mov_lot_dtl_id                                   "); // ���b�g�ڍ�ID
    sb.append("             ,mov_line_id                                      "); // ����ID
    sb.append("             ,document_type_code                               "); // �����^�C�v
    sb.append("             ,record_type_code                                 "); // ���R�[�h�^�C�v
    sb.append("             ,item_id                                          "); // OPM�i��ID
    sb.append("             ,item_code                                        "); // �i��
    sb.append("             ,lot_id                                           "); // ���b�gID
    sb.append("             ,lot_no                                           "); // ���b�gNo
    sb.append("             ,actual_date                                      "); // ���ѓ�
    sb.append("             ,actual_quantity                                  "); // ���ѐ���
    sb.append("             ,automanual_reserve_class                         "); // �����蓮�����敪
    sb.append("             ,created_by                                       "); // �쐬��
    sb.append("             ,creation_date                                    "); // �쐬��
    sb.append("             ,last_updated_by                                  "); // �ŏI�X�V��
    sb.append("             ,last_update_date                                 "); // �ŏI�X�V��
    sb.append("             ,last_update_login )                              "); // �ŏI�X�V���O�C��
    sb.append("      SELECT  xxinv_mov_lot_s1.NEXTVAL                         "); // �ړ����b�g�ڍ׎��ʗp
    sb.append("             ,:1                                               "); // ����ID(�V�K�̔�)
    sb.append("             ,xmld.document_type_code                          "); // �����^�C�v
    sb.append("             ,xmld.record_type_code                            "); // ���R�[�h�^�C�v
    sb.append("             ,xmld.item_id                                     "); // OPM�i��ID
    sb.append("             ,xmld.item_code                                   "); // �i��
    sb.append("             ,xmld.lot_id                                      "); // ���b�gID
    sb.append("             ,xmld.lot_no                                      "); // ���b�gNo
    sb.append("             ,CASE                                             "); // ���ѓ�
    sb.append("                WHEN  xmld.record_type_code = '20' THEN        "); //   ���R�[�h�^�C�v20�F�o�Ɏ��т̏ꍇ�A�o�ד��􂢑ւ�
    sb.append("                    :2                                         ");
    sb.append("                ELSE                                           "); //   ����ȊO�̏ꍇ�A�o�ד��􂢑ւ��͍s��Ȃ��B
    sb.append("                    xmld.actual_date                           ");
    sb.append("              END                                              ");
    sb.append("             ,xmld.actual_quantity                             "); // ���ѐ���
    sb.append("             ,xmld.automanual_reserve_class                    "); // �����蓮�����敪
    sb.append("             ,FND_GLOBAL.USER_ID                               "); // �쐬��
    sb.append("             ,SYSDATE                                          "); // �쐬��
    sb.append("             ,FND_GLOBAL.USER_ID                               "); // �ŏI�X�V��
    sb.append("             ,SYSDATE                                          "); // �ŏI�X�V��
    sb.append("             ,FND_GLOBAL.LOGIN_ID                              "); // �ŏI�X�V���O�C��
    sb.append("      FROM    xxinv_mov_lot_details xmld                       "); // �ړ����b�g�ڍ�
    sb.append("      WHERE   xmld.mov_line_id    = :3 ;                       "); // �󒍖��׃A�h�I��ID(����)
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      Number orderLineId       = (Number)newOrderLineID;                      // �󒍖��׃A�h�I��ID(�V�K�̔�)
      Date   actualDate        = (Date)hdrRow.getAttribute("ShippedDate");    // �o�ד�
      Number oldOrderLineID    = (Number)lineRow.getAttribute("OrderLineId"); // �󒍖��׃A�h�I��ID(����)

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId));    // �󒍖��׃A�h�I��ID(�V�K�̔�)
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualDate));   // �o�ד�
      cstmt.setInt(i++, XxcmnUtility.intValue(oldOrderLineID)); // �󒍖��׃A�h�I��ID(����)
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLotDetails 

  /***************************************************************************
   * �󒍖��׃A�h�I���̃f�[�^���X�V���܂��B
   * @param updRow - �X�V�Ώۍs
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void updateOrderLine(
    OARow updRow
    ) throws OAException
  {
    String apiName      = "updateOrderLine";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN ");
    sb.append("  UPDATE xxwsh_order_lines_all xola ");
    sb.append("  SET    xola.line_description  = :1 " ); // �E�v
    sb.append("        ,xola.last_updated_by   = FND_GLOBAL.USER_ID  "); // �ŏI�X�V��
    sb.append("        ,xola.last_update_date  = SYSDATE "            ); // �ŏI�X�V��
    sb.append("        ,xola.last_update_login = FND_GLOBAL.LOGIN_ID "); // �ŏI�X�V���O�C��
    sb.append("  WHERE  xola.order_line_id     = :2 ;                "); // �󒍖��׃A�h�I��ID
    sb.append("END; ");

    // PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(sb.toString(),
                                                                           OADBTransaction.DEFAULT);
    try
    {
      // �����擾
      String lineDescription = (String)updRow.getAttribute("LineDescription"); // �E�v
      Number orderLineId     = (Number)updRow.getAttribute("OrderLineId");     // �󒍖��׃A�h�I��ID
      
      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setString(i++, lineDescription);                 // �E�v
      cstmt.setInt(i++, XxcmnUtility.intValue(orderLineId)); // �󒍖��׃A�h�I��ID
     
      // PL/SQL���s
      cstmt.execute();

    // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
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
                              XxpoConstants.CLASS_AM_XXPO441001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // updateOrderLine 

  /***************************************************************************
   * �V�[�P���X����󒍖��׃A�h�I��ID���擾���܂��B
   * @param trans - �g�����U�N�V����
   * @return Number - �󒍃w�b�_�A�h�I��ID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public static Number getOrderLineId(
    OADBTransaction trans
    ) throws OAException
  {
    String apiName   = "getOrderLineId";

    return XxcmnUtility.getSeq(trans, XxpoConstants.XXWSH_ORDER_LINES_ALL_S1);

  } // getOrderLineId

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo441001j.server", "XxpoShippedResultAMLocal");
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
   * Container's getter for XxpoProvSearchVO1
   */
  public XxpoProvSearchVOImpl getXxpoProvSearchVO1()
  {
    return (XxpoProvSearchVOImpl)findViewObject("XxpoProvSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeHeaderVO1
   */
  public XxpoShippedMakeHeaderVOImpl getXxpoShippedMakeHeaderVO1()
  {
    return (XxpoShippedMakeHeaderVOImpl)findViewObject("XxpoShippedMakeHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeHeaderPVO1
   */
  public XxpoShippedMakeHeaderPVOImpl getXxpoShippedMakeHeaderPVO1()
  {
    return (XxpoShippedMakeHeaderPVOImpl)findViewObject("XxpoShippedMakeHeaderPVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeLinePVO1
   */
  public XxpoShippedMakeLinePVOImpl getXxpoShippedMakeLinePVO1()
  {
    return (XxpoShippedMakeLinePVOImpl)findViewObject("XxpoShippedMakeLinePVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeLineVO1
   */
  public XxpoShippedMakeLineVOImpl getXxpoShippedMakeLineVO1()
  {
    return (XxpoShippedMakeLineVOImpl)findViewObject("XxpoShippedMakeLineVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedMakeTotalVO1
   */
  public XxpoShippedMakeTotalVOImpl getXxpoShippedMakeTotalVO1()
  {
    return (XxpoShippedMakeTotalVOImpl)findViewObject("XxpoShippedMakeTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoShippedResultVO1
   */
  public XxpoShippedResultVOImpl getXxpoShippedResultVO1()
  {
    return (XxpoShippedResultVOImpl)findViewObject("XxpoShippedResultVO1");
  }
}