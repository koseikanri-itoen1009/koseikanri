/*============================================================================
* �t�@�C���� : XxinvMovementResultsLnCO
* �T�v����   : ���o�Ɏ��і���:�����R���g���[��
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-18 1.0  �勴�F�Y     �V�K�쐬
* 2008-06-11 1.2  �勴�F�Y     �s��w�E�����C��
* 2008-06-18 1.3  �勴�F�Y     �s��w�E�����C��
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAApplicationModule;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;

/***************************************************************************
 * ���o�Ɏ��і���:�����R���g���[���ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.3
 ***************************************************************************
 */
public class XxinvMovementResultsLnCO extends XxcmnOAControllerImpl
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

      // �O���URL�擾
      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);

      // mod start ver1.3
      // �O��ʂ��o�Ƀ��b�g���ׁA���Ƀ��b�g���׈ȊO�̏ꍇ�A�����������{
      //if (!XxinvConstants.URL_XXINV510002J_1.equals(prevUrl)
             //&& !XxinvConstants.URL_XXINV510002J_2.equals(prevUrl))
      //{
      // �O��ʂ̒l�擾
      String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // �]�ƈ��敪
      String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // ���уf�[�^�敪
      String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // ���i���ʋ敪
      String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
      String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG); // �X�V�t���O

      // �p�����[�^�pHashMap�ݒ�
      HashMap searchParams = new HashMap();
      searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
      searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
      searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
      searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);
      searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);

      // �����ݒ�
      Serializable setParams[] = { searchParams };
      // initialize�̈����^�ݒ�
      Class[] parameterTypes = { HashMap.class };

      // �K�p�{�^��������
      if (pageContext.getParameter("Go") != null)
      {
        // �����������Ȃ�
      } else
      {
        // VO����������
        am.invokeMethod("initializeLine", setParams, parameterTypes);
      }

      // �X�V�t���O��NULL�ȊO�̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(updateFlag))
      {
        // ��������
        am.invokeMethod("doSearchLine", setParams, parameterTypes);
      }
      //}
      // mod start ver1.3

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510001J, true))
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
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ******************************** //
      // *       ����{�^��������       * //
      // ******************************** //
      if (pageContext.getParameter("Cancel") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // ���o�Ɏ��їv���ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ******************************** //
      // *       �߂�{�^��������       * //
      // ******************************** //
      } else if (pageContext.getParameter("Back") != null)
      {
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // �]�ƈ��敪
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // ���уf�[�^�敪
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);  // ���i���ʋ敪
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
        String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG);   // �X�V�t���O

        // �p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);
        searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PREV_URL, XxinvConstants.URL_XXINV510001JL);
        
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
        // ���o�Ɏ��уw�b�_��ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          searchParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ******************************** //
      // *       �K�p�{�^��������       * //
      // ******************************** //
      } else if (pageContext.getParameter("Go") != null)
      {
        // �o�^�E�X�V���̃`�F�b�N(�i�ڏd���`�F�b�N)
        am.invokeMethod("checkLine");

        // �o�^�E�X�V����(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
        String retCode = (String)am.invokeMethod("doExecute");

        // ����I���̏ꍇ�A�R�~�b�g����
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;

          // ����I��(�X�V�L)�̏ꍇ(MovHdrId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode))
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }

          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          // �R�~�b�g
          am.invokeMethod("doCommit");

          // ����I��(�X�V�L)�̏ꍇ
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag))
          {
            // OA��O���X�g�𐶐����܂��B
            ArrayList exceptions = new ArrayList(100);

            // �R���J�����g�F�ړ����o�Ɏ��ѓo�^�������s
            HashMap retParams = new HashMap();
            retParams = (HashMap)am.invokeMethod("doMovActualMake");

            // �R���J�����g������I�������ꍇ
            if (XxcmnConstants.RETURN_SUCCESS.equals((String)retParams.get("retFlag")))
            {
              // ���b�Z�[�W�g�[�N���擾
              MessageToken[] tokens = new MessageToken[2];
              tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID, retParams.get("requestId").toString());
              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                                XxinvConstants.XXINV10006,
                                                tokens,
                                                OAException.INFORMATION,
                                                null));
            }
            // �o�^����MSG��ݒ肵�A����ʑJ��
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10161, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));
            // ���b�Z�[�W���o�͂��A�����I��
            if (exceptions.size() > 0)
            {
              try
              {
                OAException.raiseBundledOAException(exceptions);
              } catch(OAException oe)
              {
                String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // �]�ƈ��敪
                String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // ���уf�[�^�敪
                String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // ���i���ʋ敪
                String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG); // �X�V�t���O

                // �p�����[�^�pHashMap�ݒ�
                HashMap searchParams = new HashMap();
                searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
                searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
                searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
                searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, am.invokeMethod("getHdrId"));
                searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, XxinvConstants.PROCESS_FLAG_U);

                pageContext.putDialogMessage(oe);

                pageContext.forwardImmediatelyToCurrentPage(
                  searchParams,
                  true,
                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
              }
              
            }
          }

        // ����I���łȂ��ꍇ�A���[���o�b�N
        } else
        {
          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          am.invokeMethod("doRollBack");
        }

      // ******************************** //
      // *      �s�}���{�^��������      * //
      // ******************************** //
      } else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("addRowLine");

      // ********************************** //
      // *  �o�Ƀ��b�g���׃A�C�R��������  * //
      // ********************************** //
      } else if ("shippedLot".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
        // �ړ�����ID�擾
        String movLineId   = pageContext.getParameter("MOV_LINE_ID");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
        String peoplecode = pageContext.getParameter("Peoplecode");
        String hdrId       = pageContext.getParameter("HdrId");
        String updateFlag  = pageContext.getParameter("Update");

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, movLineId);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peoplecode);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, hdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);
        // �o�Ƀ��b�g�ڍ׉�ʂ֑J��
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510002J_1,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ********************************** //
      // *  ���Ƀ��b�g���׃A�C�R��������  * //
      // ********************************** //
      } else if ("shipToLot".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
        // �ړ�����ID�擾
        String movLineId   = pageContext.getParameter("MOV_LINE_ID");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
        String peoplecode = pageContext.getParameter("Peoplecode");
        String hdrId       = pageContext.getParameter("HdrId");
        String updateFlag  = pageContext.getParameter("Update");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, movLineId);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peoplecode);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, hdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);
        // �o�Ƀ��b�g�ڍ׉�ʂ֑J��
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510002J_2,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);
      }

    // ��O�����������ꍇ
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
    
  }

}
