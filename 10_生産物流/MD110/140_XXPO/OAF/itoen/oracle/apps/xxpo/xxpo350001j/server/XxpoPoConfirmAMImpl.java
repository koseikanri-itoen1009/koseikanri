/*============================================================================
* �t�@�C���� : XxpoPoConfirmAMImpl
* �T�v����   : �����m�F���:����/�����E����Ɖ��ʃA�v���P�[�V�������W���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  �ɓ��ЂƂ�     �V�K�쐬
* 2008-05-07      �ɓ��ЂƂ�     �����ύX�v���Ή�(#41,48)
* 2009-02-24 1.1  ��r�@���     �{�ԏ�Q#6�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/***************************************************************************
 * �����m�F���:����/�����E����Ɖ��ʃA�v���P�[�V�������W���[���ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.1
 ***************************************************************************
 */
public class XxpoPoConfirmAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoConfirmAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo350001j.server", "XxpoPoConfirmAMLocal");
  }

  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void initialize()
  {
    // ************************* //
    // * ������������VO ������ * //
    // ************************* //
    OAViewObject poConfirmSearchVo = getXxpoPoConfirmSearchVO1();

    // 1�s���Ȃ��ꍇ�A
    if (!poConfirmSearchVo.isPreparedForExecution())
    {
      // ��s�쐬
      poConfirmSearchVo.setMaxFetchSize(0);
      poConfirmSearchVo.insertRow(poConfirmSearchVo.createRow());
      OARow poConfirmSearchRow = (OARow)poConfirmSearchVo.first();
      // �L�[�ɒl���Z�b�g
      poConfirmSearchRow.setNewRowState(Row.STATUS_INITIALIZED);
      poConfirmSearchRow.setAttribute("RowKey", new Number(1));
    }
    // ************************* //
    // * ���[�U�[���擾      * //
    // ************************* //
    getUserData();
  }

  /***************************************************************************
   * ���[�U�[�����擾���郁�\�b�h�ł��B
   ***************************************************************************
   */
  public void getUserData()
  {
    // ���[�U�[���擾 
    HashMap retHashMap = XxpoUtility.getUserData(getOADBTransaction());                          

    // ������������VO�擾
    OAViewObject poPoConfirmSearchVo = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVo.first();
    // �]�ƈ��敪���Z�b�g
    poPoConfirmSearchRow.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // �]�ƈ��敪
    // �]�ƈ��敪��2:�O���̏ꍇ�A�d����E�H������Z�b�g
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      poPoConfirmSearchRow.setAttribute("OutSideUsrVendorId",    retHashMap.get("VendorId"));      // �����ID
      poPoConfirmSearchRow.setAttribute("OutSideUsrFactoryCode", retHashMap.get("FactoryCode")); // �H��R�[�h
    }
  }

  /***************************************************************************
   * �K�{�`�F�b�N���s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doRequiredCheck() throws OAException
  {

    // ������������VO�擾
    OAViewObject poPoConfirmSearchVo = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVo.first();
    // �l���擾
    Object fdDate  = poPoConfirmSearchRow.getAttribute("DeliveryDateFrom"); // �[����FROM

    // �[����FROM��NULL�̏ꍇ�A�G���[
// 2008-02-24 D.Nihei Add Start �{�ԏ�Q#6�Ή�
//    if (XxcmnUtility.isBlankOrNull(fdDate))
    // ����No
    Object poNum  = poPoConfirmSearchRow.getAttribute("HeaderNumber");
    if (XxcmnUtility.isBlankOrNull(poNum) 
     && XxcmnUtility.isBlankOrNull(fdDate))
// 2008-02-24 D.Nihei Add End
    {
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   poPoConfirmSearchVo.getName(),
                   poPoConfirmSearchRow.getKey(),
                   "DeliveryDateFrom",
                   fdDate,
                   XxcmnConstants.APPL_XXPO,         
                   XxpoConstants.XXPO10002);
    }

  }

  /***************************************************************************
   * �����������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doSearch()
  {
    // ������������VO�擾
    OAViewObject poPoConfirmSearchVO = getXxpoPoConfirmSearchVO1();
    OARow poPoConfirmSearchRow = (OARow)poPoConfirmSearchVO.first();
    String peopleCode = (String)poPoConfirmSearchRow.getAttribute("PeopleCode");

    HashMap searchParams = new HashMap();
    
    // �����p�����[�^�ɒl���Z�b�g
    searchParams.put("peopleCode", peopleCode); // �]�ƈ��敪

    // �]�ƈ��敪��2:�O���̏ꍇ�A�����ID�E���H��ID��ݒ�
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("outSideUsrVendorId",    poPoConfirmSearchRow.getAttribute("OutSideUsrVendorId"));
      searchParams.put("outSideUsrFactoryCode", poPoConfirmSearchRow.getAttribute("OutSideUsrFactoryCode"));
    }

    searchParams.put("headerNumber",     poPoConfirmSearchRow.getAttribute("HeaderNumber"));        // ����No.
    searchParams.put("vendorId",         poPoConfirmSearchRow.getAttribute("VendorId"));            // �����ID     
    searchParams.put("mediationId",      poPoConfirmSearchRow.getAttribute("MediationId"));         // ������ID
    searchParams.put("status",           poPoConfirmSearchRow.getAttribute("Status"));              // �X�e�[�^�X
    searchParams.put("location",         poPoConfirmSearchRow.getAttribute("Location"));            // �[�i��R�[�h
    searchParams.put("department",       poPoConfirmSearchRow.getAttribute("Department"));          // ���������R�[�h
    searchParams.put("approved",         poPoConfirmSearchRow.getAttribute("Approved"));            // �����v
    searchParams.put("purchase",         poPoConfirmSearchRow.getAttribute("Purchase"));            // �����敪
    searchParams.put("orderApproved",    poPoConfirmSearchRow.getAttribute("OrderApproved"));       // ��������
    searchParams.put("cancelSearch",     poPoConfirmSearchRow.getAttribute("CancelSearch"));        // �������
    searchParams.put("purchaseApproved", poPoConfirmSearchRow.getAttribute("PurchaseApproved"));    // �d������
    searchParams.put("peopleCode",       poPoConfirmSearchRow.getAttribute("PeopleCode"));          // �]�ƈ��敪
    searchParams.put("deliveryDateFrom", poPoConfirmSearchRow.getAttribute("DeliveryDateFrom"));    // �[����FROM
    searchParams.put("deliveryDateTo",   poPoConfirmSearchRow.getAttribute("DeliveryDateTo"));      // �[����TO
      
    // �������s
    XxpoPoConfirmVOImpl poConfirmVo = getXxpoPoConfirmVO1();
    poConfirmVo.initQuery(searchParams);

    OARow row = (OARow)poConfirmVo.first();
  }

  /***************************************************************************
   * �I���`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSelectCheck() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // �������VO�擾
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // �I���s�̂ݎ擾
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    
    // �I���`�F�b�N
    // 1�s���I������Ă��Ȃ��ꍇ�A�G���[
    if (XxcmnUtility.isBlankOrNull(rows) || rows.length == 0)
    {
      // ���I���G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXPO, 
        XxpoConstants.XXPO10144);
    }
  }

  /***************************************************************************
   * �X�V�O�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doUpdateCheck() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // �������VO�擾
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // �I���s�̂ݎ擾
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
    
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      Date   deliveryDate = (Date)row.getAttribute("DeliveryDate"); // �[����
      String statusCode   = (String)row.getAttribute("StatusCode"); // �X�e�[�^�X
      String statusDisp   = (String)row.getAttribute("StatusDisp"); // �X�e�[�^�X
        
      // �݌ɃN���[�Y�`�F�b�N�@�[�������݌ɃN���[�Y���Ă���ꍇ�A�G���[
      if (XxpoUtility.chkStockClose(
            getOADBTransaction(),  // �g�����U�N�V����
            deliveryDate))         // �[����
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                row.getKey(),
                "DeliveryDate",
                deliveryDate,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10140));
      }

      // �X�e�[�^�X�`�F�b�N�@35:���z�m��ς� �̓G���[
      if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                 row.getKey(),
                "StatusDisp",
                statusDisp,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10141));
      }

      // �X�e�[�^�X�`�F�b�N�@99:��� �̓G���[
      if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
      {
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                poPoConfirmVo.getName(),
                row.getKey(),
                "StatusDisp",
                statusDisp,
                XxcmnConstants.APPL_XXPO, 
                XxpoConstants.XXPO10142));
      }
    }

    // �G���[������ꍇ�A�C�����C�����b�Z�[�W�o��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  }

  /***************************************************************************
   * ���b�N�E�r���������s�����\�b�h�ł��B
   * @param  vo  OAViewObject
   * @param  row OARow
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void getLock(
    OAViewObject vo,
    OARow        row
  ) throws OAException
  { 
    Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // �����w�b�_�A�h�I��ID
    String lastUpdateDate = (String)row.getAttribute("LastUpdateDate");// �ŏI�X�V��
    String headerNumber   = (String)row.getAttribute("HeaderNumber");  // �����ԍ�
        
    // �����w�b�_�A�h�I�����b�N�擾�E�r���`�F�b�N
    String retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                      getOADBTransaction(), // �g�����U�N�V����
                      xxpoHeaderId,         // �����w�b�_�A�h�I��ID
                      lastUpdateDate);      // �ŏI�X�V��

    // ���b�N�G���[�̏ꍇ
    if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
    {
      // ���b�N�G���[�C�����C�����b�Z�[�W�o��
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   vo.getName(),
                   row.getKey(),
                   "HeaderNumber",
                   headerNumber,
                   XxcmnConstants.APPL_XXPO, 
                   XxpoConstants.XXPO10138);

    // �r���G���[�̏ꍇ
    } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
    {
      // �r���G���[�C�����C�����b�Z�[�W�o��
      throw new OAAttrValException(
                   OAAttrValException.TYP_VIEW_OBJECT,          
                   vo.getName(),
                   row.getKey(),
                   "HeaderNumber",
                   headerNumber,
                   XxcmnConstants.APPL_XXCMN, 
                   XxcmnConstants.XXCMN10147);
    }
  }
  /***************************************************************************
   * �������F�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doOrderApproving() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    
    // �������VO�擾
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // �I���s�̂ݎ擾
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
      
    // �I���s�S��LOOP
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // �����w�b�_�A�h�I��ID
        
      // ���������t���O��Y�ȊO�̏ꍇ�A�����������s���B
      if (XxcmnConstants.STRING_Y.equals(row.getAttribute("OrderApprovedFlag")) == false)
      {
        // �����w�b�_�A�h�I�����b�N�擾�E�r���`�F�b�N
        getLock(poPoConfirmVo, row);

        // �������F����
        String retFlag = XxpoUtility.doOrderApproving(
                    getOADBTransaction(), // �g�����U�N�V����
                    xxpoHeaderId);        // �����w�b�_�A�h�I��ID

      }
    }
    // �S������I���̏ꍇ�A�R�~�b�g
    XxpoUtility.commit(getOADBTransaction());
  }

  /***************************************************************************
   * �d�����F�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doPurchaseApproving() throws OAException
  {
    String retFlag = null;
    
    // �������VO�擾
    OAViewObject poPoConfirmVo = getXxpoPoConfirmVO1();
    // �I���s�̂ݎ擾
    Row[] rows = poPoConfirmVo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    OARow row = null;
      
    // �I���s�S��LOOP
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      Number xxpoHeaderId   = (Number)row.getAttribute("XxpoHeaderId");  // �����w�b�_�A�h�I��ID
        
      // �d�������t���O��Y�ȊO�̏ꍇ�A�d���������s���B
      if (XxcmnConstants.STRING_Y.equals(row.getAttribute("PurchaseApprovedFlag")) == false)
      {
        // �����w�b�_�A�h�I�����b�N�擾�E�r���`�F�b�N
        getLock(poPoConfirmVo, row);

        // �d�����F����
        retFlag = XxpoUtility.doPurchaseApproving(
                    getOADBTransaction(), // �g�����U�N�V����
                    xxpoHeaderId);        // �����w�b�_�A�h�I��ID

      }
    }
    // �S������I���̏ꍇ�A�R�~�b�g
    XxpoUtility.commit(getOADBTransaction());
  }

  /***************************************************************************
   * �y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // �������VO�擾
    OAViewObject vo = getXxpoPoConfirmVO1();
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
   * �����E����Ɖ��ʂ̏������������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void initialize2()
  {
    // �����E������VO�擾
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1�s���Ȃ��ꍇ�A������
    if (!poPoInquiryVo.isPreparedForExecution())
    {
      poPoInquiryVo.setWhereClauseParam(0,null);
      poPoInquiryVo.executeQuery();
      poPoInquiryVo.insertRow(poPoInquiryVo.createRow());
      // 1�s�ڂ��擾
      OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();
      // �L�[�ɒl���Z�b�g
      poPoInquiryRow.setNewRowState(Row.STATUS_INITIALIZED);
      poPoInquiryRow.setAttribute("HeaderId", new Number(-1));
    }

    // ���v�^�uVO�擾
    OAViewObject sumVo = getXxpoPoInquirySumVO1();
    // 1�s���Ȃ��ꍇ�A������
    if (!sumVo.isPreparedForExecution())
    {
      sumVo.setWhereClauseParam(0,null);
      sumVo.setWhereClauseParam(1,null);
      sumVo.setWhereClauseParam(2,null);
      sumVo.setWhereClauseParam(3,null);
      sumVo.setWhereClauseParam(4,null);
      sumVo.executeQuery();
      sumVo.insertRow(sumVo.createRow());
      // 1�s�ڂ��擾
      OARow sumRow = (OARow)sumVo.first();
      // �L�[�ɒl���Z�b�g
      sumRow.setNewRowState(Row.STATUS_INITIALIZED);
      sumRow.setAttribute("RowKey", new Number(-1));
    }

    // �����E���PVO�擾
    OAViewObject poPoInquiryPvo = getXxpoPoInquiryPVO1();      
    // 1�s���Ȃ��ꍇ�A�A������
    if (!poPoInquiryPvo.isPreparedForExecution())
    {    
      poPoInquiryPvo.setMaxFetchSize(0);
      poPoInquiryPvo.executeQuery();
      poPoInquiryPvo.insertRow(poPoInquiryPvo.createRow());
      // 1�s�ڂ��擾
      OARow poPoInquiryPvoRow = (OARow)poPoInquiryPvo.first();
      // �L�[�ɒl���Z�b�g
      poPoInquiryPvoRow.setAttribute("RowKey", new Number(1));
    }    
  }

  /***************************************************************************
   * �����E����Ɖ��ʂ̌����������s�����\�b�h�ł��B
   * @param searchHeaderId - �����p�����[�^
   ***************************************************************************
   */
  public void doSearch(String searchHeaderId)
  {
    // �w�b�_�������s
    XxpoPoInquiryVOImpl poPoInquiryVo = getXxpoPoInquiryVO1();
    poPoInquiryVo.initQuery(searchHeaderId);
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();
    // �w�b�_�f�[�^���擾�ł��Ȃ������ꍇ
    if (poPoInquiryVo.getRowCount() == 0)
    {
      // VO������
      poPoInquiryVo.setWhereClauseParam(0,null);
      poPoInquiryVo.executeQuery();
      poPoInquiryVo.insertRow(poPoInquiryVo.createRow());
      // 1�s�ڂ��擾
      poPoInquiryRow = (OARow)poPoInquiryVo.first();
      // �L�[�ɒl���Z�b�g
      poPoInquiryRow.setNewRowState(Row.STATUS_INITIALIZED);
      poPoInquiryRow.setAttribute("HeaderId", new Number(-1));

      // �����ؑ֏���
      disabledChanged("1"); 
      
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }

    Date deliveryDate  = (Date)poPoInquiryRow.getAttribute("DeliveryDate"); // �[����
    String statusCode  = (String)poPoInquiryRow.getAttribute("StatusCode"); // �X�e�[�^�X

    // ���׌������s
    XxpoPoInquiryLineVOImpl lineVo = getXxpoPoInquiryLineVO1();
    lineVo.initQuery(
      statusCode,
      deliveryDate,
      searchHeaderId);
    OARow lineRow = (OARow)lineVo.first();
    // ���׃f�[�^���擾�ł��Ȃ������ꍇ
    if (lineVo.getRowCount() == 0)
    {
      // �����ؑ֏���
      disabledChanged("1"); 
      
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }

    // ���v�^�u�������s
    XxpoPoInquirySumVOImpl sumVo = getXxpoPoInquirySumVO1();
    sumVo.initQuery(
      statusCode,
      searchHeaderId
    ); 
    OARow SumRow = (OARow)sumVo.first();
    // ���v�^�u�f�[�^���擾�ł��Ȃ������ꍇ
    if (sumVo.getRowCount() == 0)
    {
      sumVo.setWhereClauseParam(0,null);
      sumVo.setWhereClauseParam(1,null);
      sumVo.setWhereClauseParam(2,null);
      sumVo.setWhereClauseParam(3,null);
      sumVo.setWhereClauseParam(4,null);
      sumVo.executeQuery();
      sumVo.insertRow(sumVo.createRow());
      // 1�s�ڂ��擾
      OARow sumRow = (OARow)sumVo.first();
      // �L�[�ɒl���Z�b�g
      sumRow.setNewRowState(Row.STATUS_INITIALIZED);
      sumRow.setAttribute("RowKey", new Number(-1));
      
      // �����ؑ֏���
      disabledChanged("1"); 
      
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);      
    }
    // �����ؑ֏���
    disabledChanged("0"); // �L�� 
  }

  /***************************************************************************
   * �����ؑ֐�����s�����\�b�h�ł��B
   * param flag - 0:�L��
   *            - 1:����
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // �����E���PVO�擾
    OAViewObject poPoInquiryPvo = getXxpoPoInquiryPVO1();    
    // 1�s�ڂ��擾
    OARow disabledRow = (OARow)poPoInquiryPvo.first();

    // �t���O��0:�L���̏ꍇ
    if ("0".equals(flag))
    {
      disabledRow.setAttribute("OrderApprovingDisabled",    Boolean.FALSE); // ���������{�^��������
      disabledRow.setAttribute("PurchaseApprovingDisabled", Boolean.FALSE); // �d�������{�^��������
    
    // �t���O��1:�����̏ꍇ
    } else if ("1".equals(flag))
    {
      disabledRow.setAttribute("OrderApprovingDisabled",    Boolean.TRUE); // ���������{�^�������s��
      disabledRow.setAttribute("PurchaseApprovingDisabled", Boolean.TRUE); // �d�������{�^�������s��

    }
  }
  
  /***************************************************************************
   * ��������Ɖ��ʂ̍X�V�O�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doUpdateCheck2() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    // ��������Ɖ�w�b�_���VO�擾
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1�s�ڂ��擾
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();    

    Date   deliveryDate = (Date)poPoInquiryRow.getAttribute("DeliveryDate"); // �[����
    String statusCode   = (String)poPoInquiryRow.getAttribute("StatusCode"); // �X�e�[�^�X
    String statusDisp   = (String)poPoInquiryRow.getAttribute("StatusDisp"); // �X�e�[�^�X
        
    // �݌ɃN���[�Y�`�F�b�N�@�[�������݌ɃN���[�Y���Ă���ꍇ�A�G���[
    if (XxpoUtility.chkStockClose(
          getOADBTransaction(),  // �g�����U�N�V����
          deliveryDate))         // �[����
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "DeliveryDate",
              deliveryDate,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10140));
    }

    // �X�e�[�^�X�`�F�b�N�@35:���z�m��ς� �̓G���[
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "StatusDisp",
              statusDisp,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10141));
    }

    // �X�e�[�^�X�`�F�b�N�@99:��� �̓G���[
    if (XxpoConstants.STATUS_CANCEL.equals(statusCode))
    {
      exceptions.add( 
        new OAAttrValException(
              OAAttrValException.TYP_VIEW_OBJECT,          
              poPoInquiryVo.getName(),
              poPoInquiryRow.getKey(),
              "StatusDisp",
              statusDisp,
              XxcmnConstants.APPL_XXPO, 
              XxpoConstants.XXPO10142));
    }

    // �G���[������ꍇ�A�C�����C�����b�Z�[�W�o��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  }

  /***************************************************************************
   * ��������Ɖ��ʂ̔������F�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doOrderApproving2() throws OAException
  {
    String retFlag = null;
    // ��������Ɖ�w�b�_���VO�擾
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1�s�ڂ��擾
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();      
    Number xxpoHeaderId   = (Number)poPoInquiryRow.getAttribute("XxpoHeaderId");  // �����w�b�_�A�h�I��ID
    String lastUpdateDate = (String)poPoInquiryRow.getAttribute("LastUpdateDate");// �ŏI�X�V��
        
    // ���������t���O��Y�ȊO�̏ꍇ�A�����������s���B
    if (XxcmnConstants.STRING_Y.equals(poPoInquiryRow.getAttribute("OrderApprovedFlag")) == false)
    {

      // �����w�b�_�A�h�I�����b�N�擾�E�r���`�F�b�N
      retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                  getOADBTransaction(), // �g�����U�N�V����
                  xxpoHeaderId,         // �����w�b�_�A�h�I��ID
                  lastUpdateDate);      // �ŏI�X�V��

      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
      {
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
                     XxcmnConstants.APPL_XXPO, 
                     XxpoConstants.XXPO10138);

     // �r���G���[�̏ꍇ
      } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
      {
        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
           XxcmnConstants.APPL_XXCMN, 
           XxcmnConstants.XXCMN10147);
      }
 
      // �������F����
      retFlag = XxpoUtility.doOrderApproving(
                  getOADBTransaction(), // �g�����U�N�V����
                  xxpoHeaderId);        // �����w�b�_�A�h�I��ID

    }
    // �S������I���̏ꍇ�A�R�~�b�g
    XxpoUtility.commit(getOADBTransaction());

  }  

  /***************************************************************************
   * ��������Ɖ��ʂ̎d�����F�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doPurchaseApproving2() throws OAException
  {
    String retFlag = null;
    // ��������Ɖ�w�b�_���VO�擾
    OAViewObject poPoInquiryVo = getXxpoPoInquiryVO1();
    // 1�s�ڂ��擾
    OARow poPoInquiryRow = (OARow)poPoInquiryVo.first();      
    Number xxpoHeaderId   = (Number)poPoInquiryRow.getAttribute("XxpoHeaderId");  // �����w�b�_�A�h�I��ID
    String lastUpdateDate = (String)poPoInquiryRow.getAttribute("LastUpdateDate");// �ŏI�X�V��
        
    // �d�������t���O��Y�ȊO�̏ꍇ�A�d���������s���B
    if (XxcmnConstants.STRING_Y.equals(poPoInquiryRow.getAttribute("PurchaseApprovedFlag")) == false)
    {

      // �����w�b�_�A�h�I�����b�N�擾�E�r���`�F�b�N
      retFlag = XxpoUtility.getXxpoPoHeadersAllLock(
                  getOADBTransaction(), // �g�����U�N�V����
                  xxpoHeaderId,         // �����w�b�_�A�h�I��ID
                  lastUpdateDate);      // �ŏI�X�V��

      // ���b�N�G���[�̏ꍇ
      if (XxcmnConstants.RETURN_ERR1.equals(retFlag))
      {
        // ���b�N�G���[���b�Z�[�W�o��
        throw new OAException(
                     XxcmnConstants.APPL_XXPO, 
                     XxpoConstants.XXPO10138);

     // �r���G���[�̏ꍇ
      } else if (XxcmnConstants.RETURN_ERR2.equals(retFlag))
      {
        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
           XxcmnConstants.APPL_XXCMN, 
           XxcmnConstants.XXCMN10147);
      }
 
      // �d�����F����
      retFlag = XxpoUtility.doPurchaseApproving(
                  getOADBTransaction(), // �g�����U�N�V����
                  xxpoHeaderId);        // �����w�b�_�A�h�I��ID

    }
    // �S������I���̏ꍇ�A�R�~�b�g
    XxpoUtility.commit(getOADBTransaction());

  }  

// 2008-02-24 D.Nihei Add Start �{�ԏ�Q#6�Ή�
  /***************************************************************************
   * �[�����̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyDeliveryDate()
  {
    // �o�b�`�w�b�_���VO�擾
    XxpoPoConfirmSearchVOImpl vo = getXxpoPoConfirmSearchVO1();
    OARow row = (OARow)vo.first();
    // �l���擾
    Date deliveryDateFrom      = (Date)row.getAttribute("DeliveryDateFrom"); // �[�����i�J�n�j
    Date deliveryDateTo        = (Date)row.getAttribute("DeliveryDateTo");   // �[�����i�I���j
    if (XxcmnUtility.isBlankOrNull(deliveryDateTo)) 
    {
      row.setAttribute("DeliveryDateTo", deliveryDateFrom);
    }
  } // copyDeliveryDate
// 2008-02-24 D.Nihei Add End

  /**
   * 
   * Container's getter for XxpoPoConfirmSearchVO1
   */
  public XxpoPoConfirmSearchVOImpl getXxpoPoConfirmSearchVO1()
  {
    return (XxpoPoConfirmSearchVOImpl)findViewObject("XxpoPoConfirmSearchVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoConfirmVO1
   */
  public XxpoPoConfirmVOImpl getXxpoPoConfirmVO1()
  {
    return (XxpoPoConfirmVOImpl)findViewObject("XxpoPoConfirmVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryVO1
   */
  public XxpoPoInquiryVOImpl getXxpoPoInquiryVO1()
  {
    return (XxpoPoInquiryVOImpl)findViewObject("XxpoPoInquiryVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquirySumVO1
   */
  public XxpoPoInquirySumVOImpl getXxpoPoInquirySumVO1()
  {
    return (XxpoPoInquirySumVOImpl)findViewObject("XxpoPoInquirySumVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryPVO1
   */
  public XxpoPoInquiryPVOImpl getXxpoPoInquiryPVO1()
  {
    return (XxpoPoInquiryPVOImpl)findViewObject("XxpoPoInquiryPVO1");
  }

  /**
   * 
   * Container's getter for XxpoPoInquiryLineVO1
   */
  public XxpoPoInquiryLineVOImpl getXxpoPoInquiryLineVO1()
  {
    return (XxpoPoInquiryLineVOImpl)findViewObject("XxpoPoInquiryLineVO1");
  }
}