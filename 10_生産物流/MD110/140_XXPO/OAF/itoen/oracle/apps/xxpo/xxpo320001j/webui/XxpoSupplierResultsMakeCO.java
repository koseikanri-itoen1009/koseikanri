/*============================================================================
* �t�@�C���� : XxpoSupplierResultsMakeCO
* �T�v����   : �d����o�׎��ѓ���:�o�^�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-08 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;


/***************************************************************************
 * �d����o�׎��ѓ���:�o�^�R���g���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsMakeCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);
      
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �O��ʂ̒l�擾
      String searchHeaderId  = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID);  // �w�b�_�[ID
      String updateFlag      = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG);       // �X�V�t���O

      // �����p�����[�^�pHashMap�ݒ�
      HashMap searchParams = new HashMap();
      searchParams.put("searchHeaderId",  searchHeaderId);

      // �����ݒ�
      Serializable params[] = { searchParams };
      // doSearch�̈����^�ݒ�
      Class[] parameterTypes = { HashMap.class };
      
      // �������������s(�ĕ`�掞�͏������Ȃ�)
      am.invokeMethod("initialize2", params, parameterTypes);      
      
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO320001J, true))
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
      // *   ����{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO320001JS, // �}�[�W�m�F
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);        


      // ********************************* //
      // *      �������ύX��             * //
      // ********************************* //
      } else if ("ProductedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {

        // �l�擾
        String changedLineNum  = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);  // LineNumber

        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  changedLineNum);

        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
      
        // �������ύX������
        am.invokeMethod("productedDateChanged", params, parameterTypes);
 

      // ********************************* //
      // *      �K�p�{�^��������         * //
      // ********************************* //
      } else if (pageContext.getParameter("Apply") != null) 
      {
    
        // �o�^�E�X�V�`�F�b�N����
        am.invokeMethod("allCheck");

        // �X�V����(����(�X�V�L)�FHeaderID�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
        String retCode = (String)am.invokeMethod("Apply");

        // ����I���̏ꍇ�A�R�~�b�g����
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;

          // ����I��(�X�V�L)�̏ꍇ(HeaderId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode)) 
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }
        
          // ����I�����Ɏ擾�����w�b�_�[ID��ޔ�
          //String headerId = retCode;

          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

          // �R�~�b�g
          am.invokeMethod("doCommit");

          // �R���J�����g�F�W�������C���|�[�g���s
          retCode = (String)am.invokeMethod("doDSResultsMake2");

          if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
          {
            am.invokeMethod("doCommit");          
          }

          // �I�������F
          // �����p�����[�^�pHashMap�ݒ�
          //HashMap searchParams = new HashMap();
          //searchParams.put(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID,  headerId);

          // ����I��(�X�V�L)�̏ꍇ
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag)) 
          {
            // �X�V��������MSG��ݒ肵�A����ʑJ��
            throw new OAException(
                         XxcmnConstants.APPL_XXPO,
                         XxpoConstants.XXPO30042, 
                         null, 
                         OAException.INFORMATION, 
                         null);
          }
        // ����I���łȂ��ꍇ�A���[���o�b�N
        } else
        {
          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

          am.invokeMethod("doRollBack");
        }

      }

    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
