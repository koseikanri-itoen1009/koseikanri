/*============================================================================
* �t�@�C���� : XxpoSupplierResultsAMImpl
* �T�v����   : �d����o�׎��ѓ���:�����A�v���P�[�V�������W���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-06 1.0  �g������     �V�K�쐬
* 2008-05-02 1.0  �g������     �ύX�v���Ή�(#12,36,90)�A�����ύX�v���Ή�(#28,41)
* 2008-05-21 1.0  �g������     �s����O#320_3
* 2008-06-26 1.1  �k�������v   ST�s�#17/�����w�ENo3
* 2008-07-11 1.2  �ɓ��ЂƂ�   �����ύX#153 �[�����̖������`�F�b�N�ǉ�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;

import oracle.apps.fnd.common.MessageToken;

import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Row;

import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

/***************************************************************************
 * �d����o�׎��ѓ���:�����A�v���P�[�V�������W���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.1
 ***************************************************************************
 */
public class XxpoSupplierResultsAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo320001j.server", "XxpoSupplierResultsAMLocal");
  }

  /**
   * 
   * Container's getter for StatusCodeVO1
   */
  public OAViewObjectImpl getStatusCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("StatusCodeVO1");
  }




  /***************************************************************************
   * (�������)�������������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void initialize()
  {
    // *********************************** //
    // * �d����o�׎���:����VO ��s�擾  * //
    // *********************************** //
    OAViewObject resultsSearchVo = getXxpoResultsSearchVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1�s�ڂ��擾
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      // �L�[�ɒl���Z�b�g
      resultsSearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      resultsSearchRow.setAttribute("RowKey", new Number(1));
    }
       
    // ******************************* //
    // *     ���[�U�[���擾        * //
    // ******************************* //
    getUserData();

  }

  /***************************************************************************
   * (�������)���[�U�[�����擾���郁�\�b�h�ł��B
   ***************************************************************************
   */
  public void getUserData()
  {
    // ���[�U�[���擾 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // �g�����U�N�V����
                          );

    // �d����o�׎���VO�擾
    OAViewObject resultsSearchVo = getXxpoResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    // �]�ƈ��敪���Z�b�g
    resultsSearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // �]�ƈ��敪
    // �]�ƈ��敪��2:�O���̏ꍇ�A�d��������Z�b�g
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      resultsSearchRow.setAttribute("OutSideUsrVendorCode",  retHashMap.get("VendorCode"));  // �����R�[�h
      resultsSearchRow.setAttribute("OutSideUsrVendorId",    retHashMap.get("VendorId"));    // �����ID
      resultsSearchRow.setAttribute("OutSideUsrVendorName",  retHashMap.get("VendorName"));  // �����ID
      resultsSearchRow.setAttribute("OutSideUsrFactoryCode", retHashMap.get("FactoryCode")); // �H��R�[�h

    }
  }

  /***************************************************************************
   * (�������)�����������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    
    // �O�����[�U���ʃt���O�擾
    XxpoResultsSearchVOImpl xxpoResultsSearchVo = getXxpoResultsSearchVO1();
    xxpoResultsSearchVo.first();
    String peopleCode = (String)xxpoResultsSearchVo.getCurrentRow().getAttribute("PeopleCode");
    searchParams.put("PeopleCode", peopleCode);

    // �]�ƈ��敪��2:�O���̏ꍇ�A�����ID��ݒ�
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("OutSideUsrVendorCode", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorCode"));
      searchParams.put("OutSideUsrVendorId",   xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorId"));
      searchParams.put("OutSideUsrVendorName", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrVendorName"));
      searchParams.put("OutSideUsrFactoryCode", xxpoResultsSearchVo.getCurrentRow().getAttribute("OutSideUsrFactoryCode"));
    }
    
    // �d����o�׎��я��VO�擾
    XxpoSupplierResultsVOImpl xxpoSupplierResultsVo = getXxpoSupplierResultsVO1();
    // ����
    xxpoSupplierResultsVo.initQuery(
      searchParams);          // �����p�����[�^�pHashMap
     
    // 1�s�ڂ��擾
    OARow row = (OARow)xxpoSupplierResultsVo.first();
  }

  /***************************************************************************
   * (�������)�K�{�`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doRequiredCheck()
  {

    // �d����o�׎���:��������VO�擾
    OAViewObject poResultsSearchVo = getXxpoResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow poResultsSearchRow = (OARow)poResultsSearchVo.first();

    Object fdDate  = poResultsSearchRow.getAttribute("DeliveryDateFrom");

    ArrayList exceptions = new ArrayList(100);

    if (XxcmnUtility.isBlankOrNull(fdDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            poResultsSearchVo.getName(),
                            poResultsSearchRow.getKey(),
                            "DeliveryDateFrom",
                            fdDate,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10002));

      OAException.raiseBundledOAException(exceptions);
    }

  }

  /***************************************************************************
   * (�������)�y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // �������VO�擾
    OAViewObject vo = getXxpoSupplierResultsVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    
    // �I���`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
    if ((rows != null) || (rows.length != 0))
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        row.setAttribute("Selection", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * (�������)�����Ώۍs�I���`�F�b�N���s���܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkSelect() throws OAException
  {
    // �������VO�擾
    OAViewObject vo = getXxpoSupplierResultsVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    // *************************************************** //
    // * ����1:�I���`�F�b�N�{�b�N�X���I���`�F�b�N        * //
    // *************************************************** //
    if ((rows == null) || (rows.length == 0))
    {

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO30040,
                  null,
                  OAException.ERROR,
                  null);
    }
  }

  /***************************************************************************
   * (�������)�ꊇ�o�ɏ������s���܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doBatchDelivery() throws OAException
  {

    ArrayList exceptions = new ArrayList(100);

    // �������VO�擾
    OAViewObject vo = getXxpoSupplierResultsVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    // ��������VO���擾
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];
      
      String hdrId = row.getAttribute("HeaderId").toString();

      if (sb.length() > 0)
      {
        sb.append(", ");
      }

      sb.append(hdrId);
    }

    // �������{
    XxpoSupplierResultsDetailsVOImpl resultsDetailsVo = getXxpoSupplierResultsDetailsVO1();
    resultsDetailsVo.initQuery(sb.toString());
    resultsDetailsVo.getRowCount();
   
    // �`�F�b�N����
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      boolean retFlag;

      // *************************************************** //
      // * ����3:�o�Ɏ��ё��݃`�F�b�N                      * //
      // * ����4:OPM�݌ɉ�vCLOSE�`�F�b�N                  * //
      // * ����5:�����X�e�[�^�X�`�F�b�N                    * //
      // * ����6:�������׋��z�m��`�F�b�N                  * //
      // *************************************************** //
      retFlag = chkBatchDelivery(exceptions,
                                 vo,
                                 row);

      // �`�F�b�N�ŃG���[�����������ꍇ�A�㑱�����̓X�L�b�v
      if (retFlag)
      {
        continue;
      }

      // *************************************************** //
      // * ����7:�������׍X�V����                          * //
      // *************************************************** //
      detailsUpdate(row, resultsDetailsVo);
      
    }

    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      doRollBack();
      OAException.raiseBundledOAException(exceptions);

    // ��O���������Ă��Ȃ��ꍇ�́A�R�~�b�g����
    } else 
    {

      // �������׏��X�V�R�~�b�g
      doCommit();

      String retCode = doDSResultsMake();

      if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
      {
        // �v�����s
        doCommit();         

        // �X�V�������b�Z�[�W
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30050,
          null,
          OAException.INFORMATION,
          null);

      }
    }

  } // doBatchDelivery

  /***************************************************************************
   * (�������)�ꊇ�o�ɏ����̎��O�`�F�b�N���s���܂��B
   * @param exceptions �G���[���X�g
   * @param vo ��������VO
   * @param row �����Ώ۔����f�[�^
   * @return boolean �G���[����:true�A�G���[����:false
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean chkBatchDelivery(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    boolean retFlag;

    // *************************************************** //
    // * ����3:�o�Ɏ��ё��݃`�F�b�N                      * //
    // *************************************************** //
    String headerNumber = (String)row.getAttribute("HeaderNumber"); // �����ԍ�

    // �o�Ɏ��у`�F�b�N
    String chkFlag = XxpoUtility.chkDeliveryResults(
                       getOADBTransaction(),
                       headerNumber);

    // �`�F�b�N�ŃG���[�����������ꍇ
    if (XxcmnConstants.STRING_Y.equals(chkFlag))
    {

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10207,
                            null));

      // �G���[����
      return true;
    }

    // *************************************************** //
    // * ����4:OPM�݌ɉ�vCLOSE�`�F�b�N                  * //
    // *************************************************** //
    Date deliveryDate = (Date)row.getAttribute("DeliveryDate");
    retFlag = XxpoUtility.chkStockClose(
                            getOADBTransaction(),
                            deliveryDate);

    // CLOSE�̏ꍇ
    if (retFlag)
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10140,
                            null));
                            
      // �G���[����
      return true;
    }
// 2008-07-11 H.Itou Add START �[�������������̏ꍇ�A�G���[
    // *************************************************** //
    // * ����4-1:�[�����������`�F�b�N                    * //
    // *************************************************** //
    // �����敪��3�F�x�����A�x��No�ɓ��͂���̏ꍇ�A�[����
    String dShipCode     = (String)row.getAttribute("DropshipCode"); // �����敪�R�[�h
    String requestNumber = (String)row.getAttribute("RequestNumber");// �x��No

    if (XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber))
    {
      // �[�������V�X�e�����t�̓G���[
      if (XxcmnUtility.chkCompareDate(1, deliveryDate, XxpoUtility.getSysdate(getOADBTransaction())))
      {
        // ************************ //
        // * �G���[���b�Z�[�W�o�� * //
        // ************************ //
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "DeliveryDate",
                              deliveryDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10253,
                              null));
                            
        // �G���[����
        return true;
      }
    }
// 2008-07-11 H.Itou Add END

    // *************************************************** //
    // * ����5:�����X�e�[�^�X�`�F�b�N                  * //
    // *************************************************** //
    String statusCode = (String)row.getAttribute("StatusCode");
    String statusDisp = (String)row.getAttribute("StatusDisp");

    // �����X�e�[�^�X���A�w����x�̏ꍇ
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10142,
                            null));
                            
      // �G���[����
      return true;

    // �����X�e�[�^�X���A�w���z�m��ρx�̏ꍇ
    } else if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10141,
                            null));
                            
      // �G���[����
      return true;
    }

    // *************************************************** //
    // * ����6:�������׋��z�m��`�F�b�N                  * //
    // *************************************************** //
    String chkMoneyDecisionFlag = XxpoUtility.getMoneyDecisionFlag(
                                    getOADBTransaction(),
                                    headerNumber);

    // �������ׂɋ��z�m��ς̖��ׂ����݂���ꍇ
    if (XxcmnConstants.STRING_Y.equals(chkMoneyDecisionFlag))
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10208,
                            null));
                            
      // �G���[����
      return true;
    }
   
    // �G���[����
    return false;
  } // 
  

  /***************************************************************************
   * (�������)��������UPDATE�������s�����\�b�h�ł��B
   * @param supplierResultsRow ��������VO�̍s
   * @param detailsVO ��������VO
   * @return String - ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String detailsUpdate(OARow supplierResultsRow, OAViewObject detailsVO)
  {
  
    // ����VO�f�[�^�擾
    HashMap params = new HashMap();

    // �����w�b�_���擾
    Number headerId = (Number)supplierResultsRow.getAttribute("HeaderId");
    
    // ��������(�t�B���^�����O)
    Row[] rows = detailsVO.getFilteredRows("PoHeaderId", headerId);

    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      // �w�b�_�[ID
      params.put("HeaderId",          headerId.toString());
      // ����ID
      params.put("LineId",            row.getAttribute("LineId").toString());
      // �[����
      params.put("DeliveryDate",      supplierResultsRow.getAttribute("DeliveryDate"));
      
      // �d����o�א���
      String orderAmount = (String)row.getAttribute("OrderAmount");
      orderAmount = XxcmnUtility.commaRemoval(orderAmount);

      params.put("LeavingShedAmount", orderAmount);
      // ����
      params.put("ItemAmount",        row.getAttribute("ItemAmount"));
      // ���t�w��
      params.put("AppointmentDate",   row.getAttribute("AppointmentDate"));
      // ���דE�v
      params.put("Description",   row.getAttribute("Description"));
      // �ŏI�X�V��
      params.put("LastUpdateDate",    row.getAttribute("LastUpdateDate"));

      // ���b�N�擾����
      getDetailsRowLock(params);

      // �r������
      chkDetailsExclusiveControl(params);

      // �d����o�׎��і��׍X�V�F���s
      XxpoUtility.updatePoLinesAllTxns(
        getOADBTransaction(), // �g�����U�N�V����
        params                // �p�����[�^
        );
    }
    
    return XxcmnConstants.STRING_TRUE;
              
  }

  /***************************************************************************
   * (�������)�R���J�����g�F�����d���E�o�׎��э쐬�����ł��B
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String doDSResultsMake()
  {

    // ��������VO�擾
    OAViewObject supplierResultsVO = getXxpoSupplierResultsVO1();

    Row[] rows = supplierResultsVO.getFilteredRows("Selection", XxcmnConstants.STRING_Y);      

    // �I������Ă��锭������ΏۂɁA�R���J�����g�N������
    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      // �����敪�R�[�h
      String dShipCode = (String)row.getAttribute("DropshipCode");

      // �x��No.
      String requestNumber = (String)row.getAttribute("RequestNumber");

      // ����No
      String headerNumber = (String)row.getAttribute("HeaderNumber");

      // �����敪���w�x���x(3)���A�x��No.���擾�ł���ꍇ�̂ݎ��s
      if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
        && !XxcmnUtility.isBlankOrNull(requestNumber)) 
      {
        HashMap params = new HashMap(3);

        params.put("DropShipCode",  dShipCode);
        params.put("RequestNumber", requestNumber);
        params.put("HeaderNumber",  headerNumber);

        return XxpoUtility.doDropShipResultsMake(
                              getOADBTransaction(), // �g�����U�N�V����
                              params                // �p�����[�^
                              );

      }
      
    }
    
    return XxcmnConstants.RETURN_SUCCESS;
  } // doDSResultsMake

  /***************************************************************************
   * (�o�^���)�������������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void initialize2(
    HashMap searchParams
  )
  {
      
    // ******************************************* //
    // * �d����o�׎���:�o�^�w�b�_PVO ��s�擾   * //
    // ******************************************* //
    OAViewObject resultsMakeHdrPVO = getXxpoSupplierResultsMakePVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsMakeHdrPVO.isPreparedForExecution())
    {    
      // 1�s���Ȃ��ꍇ�A��s�쐬
      resultsMakeHdrPVO.setMaxFetchSize(0);
      resultsMakeHdrPVO.executeQuery();
      resultsMakeHdrPVO.insertRow(resultsMakeHdrPVO.createRow());
    }

    // 1�s�ڂ��擾
    OARow resultsMakeHdrPVORow = (OARow)resultsMakeHdrPVO.first();
    // �L�[�ɒl���Z�b�g
    resultsMakeHdrPVORow.setAttribute("RowKey", new Number(1));
 
    // *********************************************** //
    // * �d����o�׎���:�o�^�w�b�_VO �����\���s�擾  * //
    // *********************************************** //
    XxpoSupplierResultsMakeHdrVOImpl resultsMakeHdrVo = getXxpoSupplierResultsMakeHdrVO1();
    OARow resultsMakeHdrVORow = null;

    // �������{
    resultsMakeHdrVo.initQuery(searchParams);

// 20080228 add Start
    // �p�����[�^��Null�̏ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (resultsMakeHdrVo.getRowCount() == 0) 
    {
      resultsMakeHdrPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

      // ************************ //
      // * �G���[���b�Z�[�W�o�� *
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500, 
                  null, 
                  OAException.ERROR, 
                  null);      
    }
// 20080228 add End

    resultsMakeHdrVORow = (OARow)resultsMakeHdrVo.first();
    
    // ***************************************** //
    // * �d����o�׎���:�o�^�w�b�_VO ���͐���  * //
    // ***************************************** //
    String statusCode = (String)resultsMakeHdrVORow.getAttribute("StatusCode");

    // �X�e�[�^�X��"���z�m���"(35)�̏ꍇ
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // �w�b�_�̓��͐�������{
      readOnlyChangedHeader();
    }

    
    // ********************************************* //
    // * �d����o�׎���:�o�^����VO �����\���s�擾  * //
    // ********************************************* //
    String hdrId = resultsMakeHdrVORow.getAttribute("HeaderId").toString();
    XxpoSupplierResultsDetailsVOImpl resultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    // �������{
    resultsDetailsVo.initQuery(hdrId);

// 20080228 add Start
    // �p�����[�^��Null�̏ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (resultsDetailsVo.getRowCount() == 0) 
    {
      resultsMakeHdrPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500, 
                  null, 
                  OAException.ERROR, 
                  null);      
    }
// 20080228 add End

    resultsDetailsVo.first();

    // ************************************************* //
    // * �d����o�׎���:�o�^���׍��vVO �����\���s�擾  * //
    // ************************************************* //
    XxpoSupplierResultsTotalVOImpl resultsTotalVo = getXxpoSupplierResultsTotalVO1();

    // �������{
    resultsTotalVo.initQuery(hdrId);
    resultsTotalVo.first();


    // ***************************************** //
    // * �d����o�׎���:�o�^����VO ���͐���    * //
    // ***************************************** //
    readOnlyChangedDetails();

  } // initialize2

  /***************************************************************************
   * (�o�^���)���͐���(�w�b�_�[)���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void readOnlyChangedHeader()
  {
    // �d����o�׎���:�o�^�w�b�_VO�擾
    OAViewObject resultsMakeHdrPVO = getXxpoSupplierResultsMakePVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)resultsMakeHdrPVO.first();

    // �w�b�_.�E�v��ǎ��p�ɕύX
    readOnlyRow.setAttribute("DescriptionReadOnly", Boolean.TRUE);
  }

  /***************************************************************************
   * (�o�^���)���͐���(����)���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void readOnlyChangedDetails()
  {
    // �d����o�׎���:�o�^����VO�擾
    OAViewObject resultsMakeDetailsVO = getXxpoSupplierResultsDetailsVO1();
    OARow resultsMakeDetailsVORow = null;

    // �d����o�׎���:�o�^����VO�̃t�F�b�`�s�����擾
    int detailsCount = resultsMakeDetailsVO.getFetchedRowCount();

    if (detailsCount > 0) 
    {
      // ���z�m��t���O(N�F�������AY�F�����ς�)
      String moneyDecisionFlag = null;
      // �i�ڋ敪
      String itemClassCode = null;
      // ���i�敪
      String prodClassCode = null;
      // ���o�Ɋ��Z�P��
      String convUnit      = null;
      
      // 1�s��
      resultsMakeDetailsVO.first();
      
      while (resultsMakeDetailsVO.getCurrentRow() != null)
      {
        resultsMakeDetailsVORow = (OARow)resultsMakeDetailsVO.getCurrentRow();

        moneyDecisionFlag = (String)resultsMakeDetailsVORow.getAttribute("MoneyDecisionFlag");
        itemClassCode     = (String)resultsMakeDetailsVORow.getAttribute("ItemClassCode");
        prodClassCode     = (String)resultsMakeDetailsVORow.getAttribute("ProdClassCode");
        convUnit          = (String)resultsMakeDetailsVORow.getAttribute("ConvUnit");
        
        // ���z�m��t���O��"Y"(������)�̏ꍇ�AReadOnly����
        if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
        {
          readOnlyChangedMoneyFlag(resultsMakeDetailsVORow);

        } else
        {
        
          // ***************************************** //
          // * �i�ڂ����i�̏ꍇ�A�������͕ҏW�s��    * //
          // ***************************************** //
          if (!XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
          {
            // ����.������
            resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.FALSE);

          } else
          {
            // ����.������
            resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.TRUE);
          }

          // ******************************************************* //
          // * �h�����N���i(���Z�P�ʂ���)�̏ꍇ�A�����͕ҏW�s��    * //
          // ******************************************************* //
          if (chkConversion(prodClassCode, itemClassCode, convUnit))
          {
            // ����.����
            resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",    Boolean.TRUE);

          } else
          {
            // ����.����
            resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",    Boolean.FALSE);
          }

        }
        resultsMakeDetailsVO.next();
        
      }
// 20080626 Add Start
      resultsMakeDetailsVO.first();
// 20080626 Add End
    }

  }

  /***************************************************************************
   * (�o�^���)���͐���(����)�����z�m��t���O�ɔ���readOnly�ݒ���s�����\�b�h�ł��B
   * @param resultsMakeDetailsVORow ��������VO
   ***************************************************************************
   */
  private void readOnlyChangedMoneyFlag(OARow resultsMakeDetailsVORow)
  {
    // ����.����
    resultsMakeDetailsVORow.setAttribute("ItemAmountReadOnly",        Boolean.TRUE);

    // ����.������
    resultsMakeDetailsVORow.setAttribute("ProductionDateReadOnly",    Boolean.TRUE);

    // ����.�o�ɐ�
    resultsMakeDetailsVORow.setAttribute("LeavingShedAmountReadOnly", Boolean.TRUE);

    // ����.���t�w��
    resultsMakeDetailsVORow.setAttribute("AppointmentDateReadOnly",   Boolean.TRUE);

    // ����.�ܖ�����
    resultsMakeDetailsVORow.setAttribute("UseByDateReadOnly",         Boolean.TRUE);

    // ����.�E�v
    resultsMakeDetailsVORow.setAttribute("DescriptionReadOnly",       Boolean.TRUE);

    // ����.�����N1
    resultsMakeDetailsVORow.setAttribute("RankReadOnly",              Boolean.TRUE);

  }

  /***************************************************************************
   * (�o�^���)�������ύX�������ł��B
   * @param params �p�����[�^�pHashMap
   ***************************************************************************
   */
  public void productedDateChanged(HashMap params)
  {        
    // �ܖ������擾
    getUseByDate(params);
  }

  /***************************************************************************
   * (�o�^���)�ܖ��������擾���郁�\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   ***************************************************************************
   */
  public void getUseByDate(HashMap params)
  {
    String searchLineNum = 
      (String)params.get(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);
    
    // �d����o�׎��я��:�o�^����VO�擾
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();
    // 1�s�߂��擾
    OARow supplierResultsDetailRow = null;

    supplierResultsDetailsVo.first();

    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailRow = (OARow)supplierResultsDetailsVo.getCurrentRow();
      if (searchLineNum.equals(supplierResultsDetailRow.getAttribute("LineNum").toString())) 
      {
        break;
      }
      supplierResultsDetailsVo.next();
    }

    // �f�[�^�擾
    Date productedDate   = (Date)supplierResultsDetailRow.getAttribute("ProductionDate");   // ������
    Number itemId        = (Number)supplierResultsDetailRow.getAttribute("ItemId");        // �i��ID
    Number expirationDay = (Number)supplierResultsDetailRow.getAttribute("ExpirationDate"); // �ܖ�����

    // �����������͂���Ă��Ȃ�(�폜���ꂽ)�ꍇ�͎Z�o���s��Ȃ�
    if (productedDate != null) {
      // �ܖ����Ԃɒl������ꍇ�A�ܖ������擾
      if (XxcmnUtility.isBlankOrNull(expirationDay) == false)
      {
// 20080226 mod Start
        Date useByDate = XxpoUtility.getUseByDate(
// 20080226 mod End
                           getOADBTransaction(),     // �g�����U�N�V����
                           itemId,                   // INV�i��ID
                           productedDate,            // ������
                           expirationDay.toString()  // �ܖ�����
                         );

        // �ܖ��������O���o�������:�o�^VO�ɃZ�b�g
        supplierResultsDetailRow.setAttribute("UseByDate", useByDate);
    
      // �ܖ����Ԃɒl���Ȃ��ꍇ�ANULL
      } else
      {
        // �ܖ��������d����o�׎��я��:�o�^����VO�ɃZ�b�g
        supplierResultsDetailRow.setAttribute("UseByDate", productedDate);      
      }
    }
  }

  /***************************************************************************
   * (�o�^���)�o�^�E�X�V���̃`�F�b�N���s���܂��B
   ***************************************************************************
   */
  public void allCheck()
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);

    // ******************************* //
    // *   ���͒l�`�F�b�N            * //
    // ******************************* //
    messageTextCheck(exceptions);
    
    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

    // ******************************* //
    // *   �X�V�����`�F�b�N          * //
    // ******************************* //
    updateConditionCheck(exceptions);
    
    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    
  }

  /***************************************************************************
   * (�o�^���)���͒l�`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �d����o�׎��я��:�o�^����VO�擾
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    OARow supplierResultsDetailsVORow = null;

    // 1�s��   
    supplierResultsDetailsVo.first();

    // ���R�[�h���擾�ł���ԁA�`�F�b�N�����{
    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailsVORow = (OARow)supplierResultsDetailsVo.getCurrentRow();

      // �s�P�ʂł̓��̓`�F�b�N�����{
      messageTextRowCheck(supplierResultsDetailsVo,
                          supplierResultsDetailsVORow,
                          exceptions);

      supplierResultsDetailsVo.next();
    }
  }

  /***************************************************************************
   * (�o�^���)�s�P�ʂœ��͒l�`�F�b�N���s�����\�b�h�ł��B
   * @param checkVo �`�F�b�N�Ώ�VO
   * @param checkRow �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException 
  {
    // �������擾
    String itemAmount = (String)checkRow.getAttribute("ItemAmount");

    // �o�ɐ����擾
    String leavingShedAmount = (String)checkRow.getAttribute("LeavingShedAmount");


    // ******************************* //
    // *   ���͕K�{�`�F�b�N            * //
    // ******************************* //
    // �����F�K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(itemAmount)) 
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY1, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ENTRY2, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            checkVo.getName(),
                            checkRow.getKey(),
                            "ItemAmount",
                            itemAmount,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10071,
                            tokens));
      
    }

    // �o�ɐ��F�K�{�`�F�b�N
    if (XxcmnUtility.isBlankOrNull(leavingShedAmount)) 
    {

      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY1, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      tokens[1] = new MessageToken(XxpoConstants.TOKEN_ENTRY2, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            checkVo.getName(),
                            checkRow.getKey(),
                            "LeavingShedAmount",
                            leavingShedAmount,
                            XxcmnConstants.APPL_XXPO,         
                            XxpoConstants.XXPO10071,
                            tokens));
    }

    // ******************************* //
    // *   ���͒l�`�F�b�N            * //
    // ******************************* //
    //** ���������̐�(0���傫��) **//
    if (!XxcmnUtility.isBlankOrNull(itemAmount)) 
    {

      // ���l�łȂ��ꍇ�̓G���[
      if (!XxcmnUtility.chkNumeric(itemAmount, 5, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

      // 0�ȉ��̓G���[
      } else if(!XxcmnUtility.chkCompareNumeric(1, itemAmount, "0"))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);
      
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10068,
                              tokens));
      }

      checkRow.setAttribute("ItemAmount", itemAmount);

    }

    //** �o�ɐ���0�ȏ� **//
    if (!XxcmnUtility.isBlankOrNull(leavingShedAmount)) 
    {

      // ���l�łȂ��ꍇ�̓G���[
      if (!XxcmnUtility.chkNumeric(leavingShedAmount, 9, 3)) 
      {
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "LeavingShedAmount",
                              leavingShedAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10001));

      // 0�ȉ��̓G���[
      } else if(!XxcmnUtility.chkCompareNumeric(2, leavingShedAmount, "0"))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_L_S_AMOUNT);
      
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,          
                              checkVo.getName(),
                              checkRow.getKey(),
                              "LeavingShedAmount",
                              leavingShedAmount,
                              XxcmnConstants.APPL_XXPO,         
                              XxpoConstants.XXPO10068,
                              tokens));
      }

      checkRow.setAttribute("LeavingShedAmount", leavingShedAmount);

    }    
  }

  /***************************************************************************
   * (�o�^���)�X�V�����`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void updateConditionCheck(
    ArrayList exceptions
  ) throws OAException 
  {

    // ******************************* //
    // *   �w�b�_�[�֘A�`�F�b�N      * //
    // ******************************* //    
    updateConditionHdrCheck(exceptions);

    // ******************************* //
    // *   ���׊֘A�`�F�b�N      * //
    // ******************************* //    
    updateConditioDetailCheck(exceptions);

  }

  /***************************************************************************
   * (�o�^���)�w�b�_�[�֘A�̍X�V�����`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void updateConditionHdrCheck(
    ArrayList exceptions
  ) throws OAException 
  {
  
    // �d����o�׎��я��:�o�^�w�b�_�[VO�擾
    OAViewObject supplierResultsMakeHdrVo = getXxpoSupplierResultsMakeHdrVO1();
    // 1�s�ڂ��擾
    OARow supplierResultsMakeHdrVORow = (OARow)supplierResultsMakeHdrVo.first();


    // ******************************* //
    // *   �݌ɃN���[�Y�`�F�b�N      * //
    // ******************************* // 
    Date deliveryDate  = 
      (Date)supplierResultsMakeHdrVORow.getAttribute("DeliveryDate"); // �[�����擾
    
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(), // �g�����U�N�V����
          deliveryDate)         // �[����
        )
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10140));

    }

// 2008-07-11 H.Itou Add START �[�������������̏ꍇ�A�G���[
    // *************************************************** //
    // * ����4-1:�[�����������`�F�b�N                    * //
    // *************************************************** //
    // �����敪��3�F�x�����A�x��No�ɓ��͂���̏ꍇ�A�[����
      String dShipCode     = (String)supplierResultsMakeHdrVORow.getAttribute("DropshipCode"); // �����敪�R�[�h
      String requestNumber = (String)supplierResultsMakeHdrVORow.getAttribute("RequestNumber");// �x��No

      if (XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
        && !XxcmnUtility.isBlankOrNull(requestNumber))
      {
        // �[�������V�X�e�����t�̓G���[
        if (XxcmnUtility.chkCompareDate(1, deliveryDate, XxpoUtility.getSysdate(getOADBTransaction())))
        {
          // ************************ //
          // * �G���[���b�Z�[�W�o�� * //
          // ************************ //
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                supplierResultsMakeHdrVo.getName(),
                                supplierResultsMakeHdrVORow.getKey(),
                                "DeliveryDate",
                                deliveryDate,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10254,
                                null));
        }
      }
// 2008-07-11 H.Itou Add END

    // ************************************* //
    // *   ���z�m��ς݃t���O�`�F�b�N      * //
    // ************************************* //
    String statusCode  = 
      (String)supplierResultsMakeHdrVORow.getAttribute("StatusCode"); // �X�e�[�^�X�R�[�h�擾
    String statusDisp =
      (String)supplierResultsMakeHdrVORow.getAttribute("StatusDisp"); // �X�e�[�^�X���擾
      
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10141));      
    }

    // ********************************* //
    // *   ����ς݃t���O�`�F�b�N      * //
    // ********************************* //
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,          
                            supplierResultsMakeHdrVo.getName(),
                            supplierResultsMakeHdrVORow.getKey(),
                            "StatusDisp",
                            statusDisp,
                            XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10142));      
    }
  }


  /***************************************************************************
   * (�o�^���)���׊֘A�̍X�V�����`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void updateConditioDetailCheck(
    ArrayList exceptions
  ) throws OAException 
  {
    // �d����o�׎��я��:�o�^����VO�擾
    OAViewObject supplierResultsDetailsVo = getXxpoSupplierResultsDetailsVO1();

    OARow supplierResultsDetailsVORow = null;

    // 1�s��   
    supplierResultsDetailsVo.first();

    // ���R�[�h���擾�ł���ԁA�`�F�b�N�����{
    while(supplierResultsDetailsVo.getCurrentRow() != null)
    {
      supplierResultsDetailsVORow = (OARow)supplierResultsDetailsVo.getCurrentRow();

      // �s�P�ʂł̋��z�m��t���O�`�F�b�N�����{
      updateConditioDetailRowCheck(supplierResultsDetailsVo,
                                   supplierResultsDetailsVORow,
                                   exceptions);

      supplierResultsDetailsVo.next();
    }
  }

  /***************************************************************************
   * (�o�^���)�s�P�ʂōX�V����(���z�m��t���OOFF)�`�F�b�N���s�����\�b�h�ł��B
   * @param checkVo �`�F�b�N�Ώ�VO
   * @param checkRow �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void updateConditioDetailRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException 
  {

    String moneyDecisionFlag = (String)checkRow.getAttribute("MoneyDecisionFlag");
    
    if (XxcmnConstants.STRING_Y.equals(moneyDecisionFlag)) 
    {
        
      exceptions.add( new OAAttrValException(
                          OAAttrValException.TYP_VIEW_OBJECT,          
                          checkVo.getName(),
                          checkRow.getKey(),
                          "MoneyDecisionFlag",
                          moneyDecisionFlag,
                          XxcmnConstants.APPL_XXPO, 
                          XxpoConstants.XXPO10141));
    }

  }

  /***************************************************************************
   * (�o�^���)�X�V�������s�����\�b�h�ł��B
   * @return String ���^�[���R�[�h(����(�X�V�L)�FHeaderID�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
   ***************************************************************************
   */
  public String Apply()
  {

    String retCode = XxcmnConstants.STRING_TRUE;
    String updFlag = XxcmnConstants.STRING_N;

    OAViewObject makeHdrVO = getXxpoSupplierResultsMakeHdrVO1();
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // *************************** //
    // *   �w�b�_�[�X�V����      * //
    // *************************** //
    if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("Description"),               
                               makeHdrVORow.getAttribute("BaseDescription")))    // �K�p(�w�b�_�[)�F�K�p(�w�b�_�[)(DB)
    {
      // �����w�b�_�[�X�V����
      retCode = headerUpdate(makeHdrVORow);

      // �w�b�_�[�X�V�����ŃG���[�����������ꍇ�A�����𒆒f
      if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
      {
        return retCode;
      }
    
      // 20080225 add Start
      updFlag = XxcmnConstants.STRING_Y;
      // 20080225 add End
    }

    // *********************** //
    // *   ���׍X�V����      * //
    // *********************** //
    OAViewObject makeDetailsVO = getXxpoSupplierResultsDetailsVO1();
    OARow makeDetailsVORow = null;

    makeDetailsVO.first();
   
    while(makeDetailsVO.getCurrentRow() != null)
    {

      makeDetailsVORow = (OARow)makeDetailsVO.getCurrentRow();


      if ((!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ItemAmount"),               
                                 makeDetailsVORow.getAttribute("BaseItemAmount")))      // �����F�݌ɓ���(DB)
        || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("DeliveryDate"),               
                                 makeDetailsVORow.getAttribute("BaseShippingDate")))    // �[�i���F�d���o�ד�(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("LeavingShedAmount"),               
                                 makeDetailsVORow.getAttribute("BaseShippingAmount")))  // �o�ɐ��F�d����o�א���(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("AppointmentDate"),               
                                 makeDetailsVORow.getAttribute("BaseAppointmentDate"))) // ���t�w��F���t�w��(DB)
        || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("Description"),               
                                 makeDetailsVORow.getAttribute("BaseDescription"))))    // �K�p(����)�F�K�p(����)(DB)
      {

        // �������׍X�V����
        retCode = detailsUpdate2(makeHdrVORow, makeDetailsVORow);

        // �������׍X�V�����ŃG���[�����������ꍇ�A�����𒆒f
        if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
        {

          return retCode;
        }

// 20080225 add Start
        updFlag = XxcmnConstants.STRING_Y;
// 20080225 add End
      }
      
      // VO�����s�ֈړ�
      makeDetailsVO.next();
    }


    // ******************************** //
    // *   OPM���b�g�}�X�^�X�V����    * //
    // ******************************** //
    makeDetailsVO.first();
    
    while(makeDetailsVO.getCurrentRow() != null)
    {

      makeDetailsVORow = (OARow)makeDetailsVO.getCurrentRow();
// 20080521 add yoshimoto Start �s����O#320_3
      // �i�ڂ����b�g�Ώۂł���ꍇ
      Number lotCtl = (Number)makeDetailsVORow.getAttribute("LotCtl");
      
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {
// 20080521 add yoshimoto End �s����O#320_3

        if ((!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ItemAmount"),               
                                   makeDetailsVORow.getAttribute("BaseIlmItemAmount")))   // �����FOPM���b�gMST�݌ɓ���(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("ProductionDate"),               
                                   makeDetailsVORow.getAttribute("BaseProductionDate")))   // �������FOPM���b�gMST�����N����(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("UseByDate"),               
                                   makeDetailsVORow.getAttribute("BaseUseByDate")))       // �ܖ������FOPM���b�gMST�ܖ�����(DB)
          || (!XxcmnUtility.isEquals(makeDetailsVORow.getAttribute("Rank"),               
                                   makeDetailsVORow.getAttribute("BaseRank"))))           // �����N1�FOPM���b�gMST�����N1(DB)
        {
          // OPM���b�g�}�X�^�X�V����
          retCode = opmLotMstUpdate(makeHdrVORow, makeDetailsVORow);
  
          // OPM���b�g�}�X�^�X�V�����ŃG���[�����������ꍇ�A�����𒆒f
          if (XxcmnConstants.STRING_FALSE.equals(retCode)) 
          {
            return retCode;
          }
// 20080225 add Start
          updFlag = XxcmnConstants.STRING_Y;
// 20080225 add End
        }
// 20080521 add yoshimoto Start �s����O#320_3
      }
// 20080521 add yoshimoto End �s����O#320_3
      // VO�����s�ֈړ�
      makeDetailsVO.next();
    }

// 20080225 add Start
    // �X�V����������ɏI�������ꍇ�A�Č����p�Ƀw�b�_�[ID��߂�
    if (XxcmnConstants.STRING_Y.equals(updFlag)) 
    {
// 20080225 add End
      retCode = makeHdrVORow.getAttribute("HeaderId").toString();

    // �X�V�����I�������ꍇ�ASTRING_TRUE��߂�
    }else
    {
      retCode = XxcmnConstants.STRING_TRUE;
    }

    return retCode;
    
  }

  /***************************************************************************
   * (�o�^���)�����w�b�_UPDATE�������s�����\�b�h�ł��B
   * @param makeHdrVORow �X�V�Ώۍs
   * @return String ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String headerUpdate(OARow makeHdrVORow)
  {
    // �d����o�׎��уw�b�_�[VO�f�[�^�擾
    HashMap params = new HashMap();

    // �w�b�_�[ID
    params.put("HeaderId",    makeHdrVORow.getAttribute("HeaderId").toString());
    // �K�p
    params.put("Description", makeHdrVORow.getAttribute("Description"));
    // �ŏI�X�V��
    params.put("LastUpdateDate", makeHdrVORow.getAttribute("LastUpdateDate"));

    // ���b�N�擾����
    getHeaderRowLock(params);

    // �r������
    chkHdrExclusiveControl(params);

    // �d����o�׎��уw�b�_�[�X�V�F���s
    String retCode =  XxpoUtility.updatePoHeadersAllTxns(
                        getOADBTransaction(), // �g�����U�N�V����
                        params                // �p�����[�^
                        );

    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
    
  }

  /***************************************************************************
   * (�o�^���)�����w�b�_�̃��b�N�������s�����\�b�h�ł��B
   * @param params �p�����[�^
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getHeaderRowLock(
    HashMap params
  ) throws OAException 
  {
   
    String apiName = "getHeaderRowLock";

    // �w�b�_�[Id
    String headerId = (String)params.get("HeaderId");
    
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pha_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pha.po_header_id header_id "); // �w�b�_�[ID
    sb.append("    FROM   PO_HEADERS_ALL pha ");         // �����w�b�_
    sb.append("    WHERE  pha.po_header_id = TO_NUMBER(:1) ");
    sb.append("    FOR UPDATE OF pha.po_header_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pha_cur; ");
    sb.append("  CLOSE pha_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, headerId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ���[���o�b�N
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10138);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        doRollBack();

        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getRowLock

  /***************************************************************************
   * (�o�^���)�����w�b�_�[�̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   ***************************************************************************
   */
  public void chkHdrExclusiveControl(
    HashMap params)
  {
    String apiName  = "chkHdrExclusiveControl";
    OAViewObject vo = null;
    OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pha.PO_HEADER_ID) cnt "); // �����w�b�_ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   PO_HEADERS_ALL pha ");          // �����w�b�_
      sb.append("  WHERE  pha.PO_HEADER_ID = TO_NUMBER(:2) ");       // �����w�b�_ID
      sb.append("  AND    TO_CHAR(pha.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // �����w�b�_���
      vo  = getXxpoSupplierResultsMakeHdrVO1();

      // �X�V�s�擾
      row = (OARow)vo.first();
  
      // �e������擾���܂��B
      String headerId          = (String)params.get("HeaderId"); // �����w�b�_ID 
      String hdrLastUpdateDate = (String)params.get("LastUpdateDate"); // �ŏI�X�V��
      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, Integer.parseInt(headerId));
      cstmt.setString(i++, hdrLastUpdateDate);
      
      cstmt.execute();
      
      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0) 
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkHdrExclusiveControl

  /***************************************************************************
   * (�o�^���)��������UPDATE�������s�����\�b�h�ł��B
   * @param makeHdrVORow �w�b�_�[VO�̍s
   * @param makeDetailsVORow ����VO�̍s
   * @return String - ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String detailsUpdate2(OARow makeHdrVORow, OARow makeDetailsVORow)
  {
    // �d����o�׎��і���VO�f�[�^�擾
    HashMap params = new HashMap();
    

    // �w�b�_�[ID
    params.put("HeaderId",          makeDetailsVORow.getAttribute("PoHeaderId").toString());

    // ����ID
    params.put("LineId",            makeDetailsVORow.getAttribute("LineId").toString());

    // ����
    params.put("ItemAmount",        makeDetailsVORow.getAttribute("ItemAmount"));
    // �[�i��
    params.put("DeliveryDate",      makeHdrVORow.getAttribute("DeliveryDate"));
    // �o�ɐ�
    params.put("LeavingShedAmount", makeDetailsVORow.getAttribute("LeavingShedAmount"));
    // ���t�w��
    params.put("AppointmentDate",   makeDetailsVORow.getAttribute("AppointmentDate"));
    // �K�p(����)
    params.put("Description",       makeDetailsVORow.getAttribute("Description"));
    // �ŏI�X�V��
    params.put("LastUpdateDate",    makeDetailsVORow.getAttribute("LastUpdateDate"));

    // ���b�N�擾����
    getDetailsRowLock(params);

    // �r������
    chkDetailsExclusiveControl(params);

    // �d����o�׎��і��׍X�V�F���s
    String retCode =  XxpoUtility.updatePoLinesAllTxns(
                        getOADBTransaction(), // �g�����U�N�V����
                        params                // �p�����[�^
                        );

    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
              
  }

  /***************************************************************************
   * (�o�^���)�������ׂ̃��b�N�������s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getDetailsRowLock(
    HashMap params
  ) throws OAException 
  {

    String headerId = (String)params.get("HeaderId");
    String lineId   = (String)params.get("LineId");
    
    String apiName = "getDetailsRowLock";
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pla_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pla.po_line_id line_id "); // �w�b�_�[ID
    sb.append("    FROM   PO_LINES_ALL pla ");           // ��������
    sb.append("    WHERE  pla.po_header_id = TO_NUMBER(:1) ");
    sb.append("    AND    pla.po_line_id   = TO_NUMBER(:2) ");
    sb.append("    FOR UPDATE OF pla.po_line_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pla_cur; ");
    sb.append("  CLOSE pla_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, headerId);
      cstmt.setString(i++, lineId);
      
      cstmt.execute();

    } catch (SQLException s) 
    {
      // ���[���o�b�N
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10138);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        doRollBack();
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getDetailsRowLock

  /***************************************************************************
   * (�o�^���)�������ׂ̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   ***************************************************************************
   */
  public void chkDetailsExclusiveControl(
    HashMap params
  )
  {
    String apiName  = "chkDetailsExclusiveControl";
    //OAViewObject vo = null;
    //OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pla.PO_LINE_ID) cnt "); // �����w�b�_ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   PO_LINES_ALL pla ");            // ��������
      sb.append("  WHERE  pla.PO_HEADER_ID = TO_NUMBER(:2) ");       // �����w�b�_ID
      sb.append("  AND    pla.po_line_id   = TO_NUMBER(:3) ");        // ���׍s�ԍ�
      sb.append("  AND    TO_CHAR(pla.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // �������׏��
      //vo  = getXxpoSupplierResultsDetailsVO1();
      //int fetchedRowCount = vo.getFetchedRowCount();
      
      
      // �e������擾���܂��B
      String headerId          = (String)params.get("HeaderId");       // �����w�b�_ID 
      String lineId            = (String)params.get("LineId");         // �X�V�Ώۖ���ID
      String dtlLastUpdateDate = (String)params.get("LastUpdateDate"); // �ŏI�X�V��

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, Integer.parseInt(headerId));
      cstmt.setInt(i++, Integer.parseInt(lineId));
      cstmt.setString(i++, dtlLastUpdateDate);
      
      cstmt.execute();
      
      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0) 
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkDetailsExclusiveControl


  /***************************************************************************
   * (�o�^���)OPM���b�g�}�X�^UPDATE�������s�����\�b�h�ł��B
   * @param makeHdrVORow �w�b�_�[VO�̍s
   * @param makeDetailsVORow ����VO�̍s
   * @return String ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String opmLotMstUpdate(OARow makeHdrVORow, OARow makeDetailsVORow)
  {    
    // �d����o�׎��і���VO�f�[�^�擾
    HashMap params = new HashMap();

    // ����
    params.put("ItemAmount",        makeDetailsVORow.getAttribute("ItemAmount"));
    // ������
    params.put("ProductionDate",    makeDetailsVORow.getAttribute("ProductionDate"));
    // �ܖ�����
    params.put("UseByDate",         makeDetailsVORow.getAttribute("UseByDate"));
    // �����N1
    params.put("Rank",              makeDetailsVORow.getAttribute("Rank"));
    // �i��ID
    params.put("ItemId",            makeDetailsVORow.getAttribute("ItemId"));
    // ���b�gNo
    params.put("LotNo",             makeDetailsVORow.getAttribute("LotNo"));
    // �ŏI�X�V��
    params.put("LotLastUpdateDate", makeDetailsVORow.getAttribute("LotLastUpdateDate"));

    // ���b�N�擾����
    getOpmLotMstRowLock(params);

    // �r������
    chkOpmLotMstExclusiveControl(params);

    // OPM���b�g�}�X�^�X�V�F���s
    String retCode =  XxpoUtility.updateIcLotsMstTxns(
                        getOADBTransaction(), // �g�����U�N�V����
                        params                // �p�����[�^
                        );
              
    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    } 

    return XxcmnConstants.STRING_TRUE;
    
  }

  /***************************************************************************
   * (�o�^���)OPM���b�gMST�̃��b�N�������s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getOpmLotMstRowLock(
    HashMap params
  ) throws OAException 
  {

    String lotNo = (String)params.get("LotNo");

    Number itemId = (Number)params.get("ItemId");

    String apiName = "getOpmLotMstRowLock";
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR lotMst_cur ");
    sb.append("  IS ");
    sb.append("    SELECT ilm.lot_id lot_id ");    // ���b�gID
    sb.append("    FROM   IC_LOTS_MST ilm ");      // OPM���b�gMST
    sb.append("    WHERE  ilm.LOT_NO  = :1 ");
    sb.append("    AND    ilm.ITEM_ID = :2 ");
    sb.append("    FOR UPDATE OF ilm.lot_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  lotMst_cur; ");
    sb.append("  CLOSE lotMst_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, lotNo);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));

      cstmt.execute();

    } catch (SQLException s) 
    {
      // ���[���o�b�N
      doRollBack();
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10138);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        // ���[���o�b�N
        doRollBack();
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }        
  } // getOpmLotMstRowLock


  /***************************************************************************
   * (�o�^���)OPM���b�gMST�r������`�F�b�N���s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   ***************************************************************************
   */
  public void chkOpmLotMstExclusiveControl(
    HashMap params
  )
  {
    String apiName  = "chkOpmLotMstExclusiveControl";
    //OAViewObject vo = null;
    //OARow row       = null;
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(ilm.lot_id) cnt "); // �����w�b�_ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   IC_LOTS_MST ilm ");             // OPM���b�g�}�X�^
      sb.append("  WHERE  ilm.item_id = :2 ");            // �i��ID
      sb.append("  AND    ilm.LOT_NO  = :3 ");            // ���b�gNo
      sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);
                
      // �����w�b�_���
      //vo  = getXxpoSupplierResultsDetailsVO1();
      //int fetchedRowCount = vo.getFetchedRowCount();

      // �e������擾���܂��B
      Number itemId            = (Number)params.get("ItemId");            // �i��ID 
      String lotNum            = (String)params.get("LotNo");             // ���b�gNo
      String lotLastUpdateDate = (String)params.get("LotLastUpdateDate"); // �ŏI�X�V��

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, lotNum);
      cstmt.setString(i++, lotLastUpdateDate);
      
      cstmt.execute();
      
      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0) 
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s) 
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s) 
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO320001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkOpmLotMstExclusiveControl

  /***************************************************************************
   * (����)�R�~�b�g�������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doCommit(
  ) throws OAException
  {
    // �R�~�b�g
    getOADBTransaction().commit();
  } // doCommit

  /***************************************************************************
   * (�o�^���)�R���J�����g�F�����d���E�o�׎��э쐬�����ł��B
   * @return String - ���^�[���R�[�h
   ***************************************************************************
   */
  public String doDSResultsMake2()
  {

    // �d����o�׎��уw�b�_�[VO�擾
    OAViewObject supplierResultsMakeHdrVO = getXxpoSupplierResultsMakeHdrVO1();

    OARow row = (OARow)supplierResultsMakeHdrVO.first();


    // �����敪�R�[�h
    String dShipCode = (String)row.getAttribute("DropshipCode");

    // �x��No.
    String requestNumber = (String)row.getAttribute("RequestNumber");

    // ����No
    String headerNumber = (String)row.getAttribute("HeaderNumber");

    // �����敪���w�x���x(3)���A�x��No.���擾�ł���ꍇ�̂ݎ��s
    if(XxpoConstants.DSHIP_PROVISION.equals(dShipCode) 
      && !XxcmnUtility.isBlankOrNull(requestNumber)) 
    {
      HashMap params = new HashMap(3);

      params.put("DropShipCode",  dShipCode);
      params.put("RequestNumber", requestNumber);
      params.put("HeaderNumber",  headerNumber);

      return XxpoUtility.doDropShipResultsMake(
                            getOADBTransaction(), // �g�����U�N�V����
                            params                // �p�����[�^
                            );

    }

    return XxcmnConstants.RETURN_SUCCESS;
  } // doDSResultsMake2

  /***************************************************************************
   * (����)���[���o�b�N�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doRollBack()
  {
    // �Z�[�u�|�C���g�܂Ń��[���o�b�N���A�R�~�b�g
    XxpoUtility.rollBack(getOADBTransaction());
  } // doRollBack

  /***************************************************************************
   * (�o�^���)�h�����N���i(���Z�P�ʂ���)�`�F�b�N���s�����\�b�h�ł��B
   * @param prodClassCode ���i�敪
   * @param itemClassCode �i�ڋ敪
   * @param convUnit ���o�Ɋ��Z�P��
   * @return true:���Z�K�v�Afalse:���Z�s�v
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean chkConversion(
    String prodClassCode,
    String itemClassCode,
    String convUnit
  ) throws OAException
  {

    // ���i�敪2(�h�����N)���A�i�ڋ敪5(���i)���A���o�Ɋ��Z�P�ʂ��u�����N�ȊO�̏ꍇ
    if ((XxpoConstants.PROD_CLASS_DRINK.equals(prodClassCode))
      && (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
      && !(XxcmnUtility.isBlankOrNull(convUnit)))
    {

      // ���Z���K�v
      return true;

    }

    // ���Z�͕s�v
    return false;

  } // chkConversion

  /**
   * 
   * Container's getter for XxpoResultsSearchVO1
   */
  public XxpoResultsSearchVOImpl getXxpoResultsSearchVO1()
  {
    return (XxpoResultsSearchVOImpl)findViewObject("XxpoResultsSearchVO1");
  }

  /**
   * 
   * Container's getter for ApprovedReqCodeVO1
   */
  public OAViewObjectImpl getApprovedReqCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedReqCodeVO1");
  }

  /**
   * 
   * Container's getter for DropShipCodeVO1
   */
  public OAViewObjectImpl getDropShipCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("DropShipCodeVO1");
  }

  /**
   * 
   * Container's getter for ApprovedCodeVO1
   */
  public OAViewObjectImpl getApprovedCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedCodeVO1");
  }


  /**
   * 
   * Container's getter for XxpoSupplierResultsMakePVO1
   */
  public XxpoSupplierResultsMakePVOImpl getXxpoSupplierResultsMakePVO1()
  {
    return (XxpoSupplierResultsMakePVOImpl)findViewObject("XxpoSupplierResultsMakePVO1");
  }


  /**
   * 
   * Container's getter for XxpoSupplierResultsTotalVO1
   */
  public XxpoSupplierResultsTotalVOImpl getXxpoSupplierResultsTotalVO1()
  {
    return (XxpoSupplierResultsTotalVOImpl)findViewObject("XxpoSupplierResultsTotalVO1");
  }


  /**
   * 
   * Container's getter for XxpoSupplierResultsMakeHdrVO1
   */
  public XxpoSupplierResultsMakeHdrVOImpl getXxpoSupplierResultsMakeHdrVO1()
  {
    return (XxpoSupplierResultsMakeHdrVOImpl)findViewObject("XxpoSupplierResultsMakeHdrVO1");
  }

  /**
   * 
   * Container's getter for XxpoSupplierResultsVO1
   */
  public XxpoSupplierResultsVOImpl getXxpoSupplierResultsVO1()
  {
    return (XxpoSupplierResultsVOImpl)findViewObject("XxpoSupplierResultsVO1");
  }

  /**
   * 
   * Container's getter for XxpoSupplierResultsDetailsVO1
   */
  public XxpoSupplierResultsDetailsVOImpl getXxpoSupplierResultsDetailsVO1()
  {
    return (XxpoSupplierResultsDetailsVOImpl)findViewObject("XxpoSupplierResultsDetailsVO1");
  }




  
}
