/*============================================================================
* ファイル名 : XxcsoSpDecisionPropertyUtils
* 概要説明   : 自販機設置契約情報登録 登録情報反映ユーティリティクラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-02 1.0  SCS柳平直人  新規作成
* 2009-05-25 1.1  SCS柳平直人  [ST障害T1_1136]LOVPK項目設定対応
* 2010-03-01 1.2  SCS阿部大輔  [E_本稼動_01678]現金支払対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
// 2010-03-01 [E_本稼動_01678] Add Start
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVORowImpl;
// 2010-03-01 [E_本稼動_01678] Add End

/*******************************************************************************
 * 自販機設置契約情報登録 登録情報反映ユーティリティクラス。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistReflectUtils 
{

  /*****************************************************************************
   * 物件情報内容反映。
   * @param pageRndrVo  ページ属性設定ビューインスタンス
   * @param mngVo       契約管理テーブル情報ビューインスタンス
   *****************************************************************************
   */
  public static void reflectInstallInfo(
    XxcsoPageRenderVOImpl                pageRndrVo
   ,XxcsoContractManagementFullVOImpl    mngVo
  )
  {
    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // ///////////////////////////////////
    // オーナー変更チェックボックスの値により値を制御
    // //////////////////////////////////
    // 物件コード
    if ( ! XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
            pageRndrVoRow.getOwnerChangeFlag()
         ) 
    )
    {
      mngVoRow.setInstallCode(null);
// 2009-05-25 [ST障害T1_1136] Add Start
      mngVoRow.setInstanceId(null);
// 2009-05-25 [ST障害T1_1136] Add End
    }
  }
// 2010-03-01 [E_本稼動_01678] Add Start
  /*****************************************************************************
   * 口座情報内容反映。
   * @param bm1DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm1BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   * @param bm2DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm2BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   * @param bm3DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm3BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectBankAccount(
    XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm1BankAccountFullVOImpl       bm1BankAccVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm2BankAccountFullVOImpl       bm2BankAccVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
   ,XxcsoBm3BankAccountFullVOImpl       bm3BankAccVo
  )
  {
    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm1BankAccountFullVORowImpl bm1BankAccVoRow
      = (XxcsoBm1BankAccountFullVORowImpl) bm1BankAccVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm2BankAccountFullVORowImpl bm2BankAccVoRow
      = (XxcsoBm2BankAccountFullVORowImpl) bm2BankAccVo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    XxcsoBm3BankAccountFullVORowImpl bm3BankAccVoRow
      = (XxcsoBm3BankAccountFullVORowImpl) bm3BankAccVo.first();

    // BM１，２，３の支払方法が現金支払の場合、口座情報を初期化
    if ( bm1DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm1DestVoRow.getBellingDetailsDiv()))
      {
        // 振込手数料負担
        if (bm1DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm1DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm1DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // 銀行番号
        if (bm1BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBankNumber()))
        {
          bm1BankAccVoRow.setBankNumber(null);
        }
        // 金融機関名
        if (bm1BankAccVoRow.getBankName() != null && 
            ! "".equals(bm1BankAccVoRow.getBankName()))
        {
          bm1BankAccVoRow.setBankName(null);
        }
        // 支店番号
        if (bm1BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBranchNumber()))
        {
          bm1BankAccVoRow.setBranchNumber(null);
        }
        // 支店名
        if (bm1BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm1BankAccVoRow.getBranchName()))
        {
          bm1BankAccVoRow.setBranchName(null);
        }
        // 口座種別
        if (bm1BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountType()))
        {
          bm1BankAccVoRow.setBankAccountType(null);
        }
        // 口座番号
        if (bm1BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNumber()))
        {
          bm1BankAccVoRow.setBankAccountNumber(null);
        }
        // 口座名義カナ
        if (bm1BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNameKana()))
        {
          bm1BankAccVoRow.setBankAccountNameKana(null);
        }
        // 口座名義漢字
        if (bm1BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm1BankAccVoRow.getBankAccountNameKanji()))
        {
          bm1BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
    if ( bm2DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm2DestVoRow.getBellingDetailsDiv()))
      {
        // 振込手数料負担
        if (bm2DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm2DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm2DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // 銀行番号
        if (bm2BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBankNumber()))
        {
          bm2BankAccVoRow.setBankNumber(null);
        }
        // 金融機関名
        if (bm2BankAccVoRow.getBankName() != null && 
            ! "".equals(bm2BankAccVoRow.getBankName()))
        {
          bm2BankAccVoRow.setBankName(null);
        }
        // 支店番号
        if (bm2BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBranchNumber()))
        {
          bm2BankAccVoRow.setBranchNumber(null);
        }
        // 支店名
        if (bm2BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm2BankAccVoRow.getBranchName()))
        {
          bm2BankAccVoRow.setBranchName(null);
        }
        // 口座種別
        if (bm2BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountType()))
        {
          bm2BankAccVoRow.setBankAccountType(null);
        }
        // 口座番号
        if (bm2BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNumber()))
        {
          bm2BankAccVoRow.setBankAccountNumber(null);
        }
        // 口座名義カナ
        if (bm2BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNameKana()))
        {
          bm2BankAccVoRow.setBankAccountNameKana(null);
        }
        // 口座名義漢字
        if (bm2BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm2BankAccVoRow.getBankAccountNameKanji()))
        {
          bm2BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
    if ( bm3DestVoRow != null )
    {
      if ( XxcsoContractRegistConstants.BM_PAYMENT_TYPE4.equals(bm3DestVoRow.getBellingDetailsDiv()))
      {
        // 振込手数料負担
        if (bm3DestVoRow.getBankTransferFeeChargeDiv() != null && 
            ! "".equals(bm3DestVoRow.getBankTransferFeeChargeDiv()))
        {
          bm3DestVoRow.setBankTransferFeeChargeDiv(null);
        }
        // 銀行番号
        if (bm3BankAccVoRow.getBankNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBankNumber()))
        {
          bm3BankAccVoRow.setBankNumber(null);
        }
        // 金融機関名
        if (bm3BankAccVoRow.getBankName() != null && 
            ! "".equals(bm3BankAccVoRow.getBankName()))
        {
          bm3BankAccVoRow.setBankName(null);
        }
        // 支店番号
        if (bm3BankAccVoRow.getBranchNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBranchNumber()))
        {
          bm3BankAccVoRow.setBranchNumber(null);
        }
        // 支店名
        if (bm3BankAccVoRow.getBranchName() != null && 
            ! "".equals(bm3BankAccVoRow.getBranchName()))
        {
          bm3BankAccVoRow.setBranchName(null);
        }
        // 口座種別
        if (bm3BankAccVoRow.getBankAccountType() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountType()))
        {
          bm3BankAccVoRow.setBankAccountType(null);
        }
        // 口座番号
        if (bm3BankAccVoRow.getBankAccountNumber() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNumber()))
        {
          bm3BankAccVoRow.setBankAccountNumber(null);
        }
        // 口座名義カナ
        if (bm3BankAccVoRow.getBankAccountNameKana() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNameKana()))
        {
          bm3BankAccVoRow.setBankAccountNameKana(null);
        }
        // 口座名義漢字
        if (bm3BankAccVoRow.getBankAccountNameKanji() != null && 
            ! "".equals(bm3BankAccVoRow.getBankAccountNameKanji()))
        {
          bm3BankAccVoRow.setBankAccountNameKanji(null);
        }
      }
    }
  }

// 2010-03-01 [E_本稼動_01678] Add End
}