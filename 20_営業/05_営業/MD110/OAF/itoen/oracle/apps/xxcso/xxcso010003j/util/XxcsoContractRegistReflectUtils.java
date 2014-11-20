/*============================================================================
* ファイル名 : XxcsoSpDecisionPropertyUtils
* 概要説明   : 自販機設置契約情報登録 登録情報反映ユーティリティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-02 1.0  SCS柳平直人  新規作成
* 2009-05-25 1.1  SCS柳平直人  [ST障害T1_1136]LOVPK項目設定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;

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

}