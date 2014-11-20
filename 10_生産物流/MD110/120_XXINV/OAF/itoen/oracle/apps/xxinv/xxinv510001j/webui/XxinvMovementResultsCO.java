/*============================================================================
* �t�@�C���� : XxinvMovementResultsCO
* �T�v����   : ���o�Ɏ��їv��:�����R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �勴�F�Y     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * ���o�Ɏ��їv��:�����R���g���[���ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementResultsCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ���̓p�����[�^�擾
      String actualFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG); // ���уf�[�^�敪
      String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // ���i���ʋ敪

      // �����p�����[�^�pHashMap�ݒ�
      HashMap searchParams = new HashMap();
      searchParams.put("actualFlag",          actualFlag);
      searchParams.put("productFlag",       productFlag);

      // �����ݒ�
      Serializable params[] = { searchParams };

      // initialize�̈����^�ݒ�
      Class[] parameterTypes = { HashMap.class };

      // �������������s
      am.invokeMethod("initialize", params, parameterTypes);

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if  (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510001J, true))
      {
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      }
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    try
    {
      // ************************* //
      // *   �i�ރ{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // ���������擾
        String movNum              = pageContext.getParameter("TxtMovNum");              // �ړ��ԍ�
        String movType             = pageContext.getParameter("TxtMovType");             // �ړ��^�C�v
        String status              = pageContext.getParameter("TxtStatus");              // �X�e�[�^�X
        String shippedLocatId      = pageContext.getParameter("TxtShippedLocatId");      // �o�Ɍ�
        String shipToLocatId       = pageContext.getParameter("TxtShipToLocatId");       // ���ɐ�
        String shipDateFrom        = pageContext.getParameter("TxtShipDateFrom");        // �o�ɓ�(�J�n)
        String shipDateTo          = pageContext.getParameter("TxtShipDateTo");          // �o�ɓ�(�I��)
        String arrivalDateFrom     = pageContext.getParameter("TxtArrivalDateFrom");     // ����(�J�n)
        String arrivalDateTo       = pageContext.getParameter("TxtArrivalDateTo");       // ����(�I��)
        String instructionPostCode = pageContext.getParameter("TxtInstructionPostCode"); // �ړ��w������
        String deliveryNo          = pageContext.getParameter("TxtDeliveryNo");          // �z��No.
        String peopleCode          = pageContext.getParameter("Peoplecode");             // �]�ƈ��敪
        String actualFlag          = pageContext.getParameter("Actual");                 // ���уf�[�^�敪
        String productFlag         = pageContext.getParameter("Product");                // ���i���ʋ敪

        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put("movNum",              movNum);
        searchParams.put("movType",             movType);
        searchParams.put("status",              status);
        searchParams.put("shippedLocatId",      shippedLocatId);
        searchParams.put("shipToLocatId",       shipToLocatId);
        searchParams.put("shipDateFrom",        shipDateFrom);
        searchParams.put("shipDateTo",          shipDateTo);
        searchParams.put("arrivalDateFrom",     arrivalDateFrom);
        searchParams.put("arrivalDateTo",       arrivalDateTo);
        searchParams.put("instructionPostCode", instructionPostCode);
        searchParams.put("deliveryNo",          deliveryNo);
        searchParams.put("peopleCode",          peopleCode);
        searchParams.put("actualFlag",          actualFlag);
        searchParams.put("productFlag",         productFlag);

        // �����ݒ�
        Serializable params[] = { searchParams };

        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // �������ڃ`�F�b�N
        am.invokeMethod("doItemCheck", params, parameterTypes); 

        // ����
        am.invokeMethod("doSearch", params, parameterTypes);

      // ************************* //
      // *   �폜�{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // �ĕ\��
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JS, // �}�[�W�m�F
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ************************* //
      // *   �V�K�{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("New") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // �p�����[�^�擾
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");

        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);

        // ���o�Ɏ��уw�b�_��ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);


      // ************************* //
      // *   �����N�N���b�N��    * //
      // ************************* //
      } else if ("MovNumberClick".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // ��������(�ړ��w�b�_ID)�擾
        String searchMovHdrId = pageContext.getParameter("searchMovHdrId");

        // �p�����[�^�擾
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");

        // ���o�Ɏ��уw�b�_��ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // *********************************** //
      // *   �o�ɓ�FROM���ύX���ꂽ�ꍇ    * //
      // *********************************** //
      } else if ("shipDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �R�s�[����
        am.invokeMethod("copyShipDate");

      // ********************************* //
      // *   ����FROM���ύX���ꂽ�ꍇ    * //
      // ********************************* //
      }  else if ("arrivalDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �R�s�[����
        am.invokeMethod("copyArrivalDate");
      }
      
    // ��O�����������ꍇ    
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
